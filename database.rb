#
# Automated tasks to maintain the Simulation Database
#
#

require 'rubygems'
require 'active_record'
require 'active_support'

require '/usr/local/daimoku-rails/app/models/simcharacter.rb'
require '/usr/local/daimoku-rails/app/models/simperson.rb'
require '/usr/local/daimoku-rails/app/models/simplace.rb'
require '/usr/local/daimoku-rails/app/models/simthing.rb'
require '/usr/local/daimoku-rails/app/models/simdoor.rb'
require '/usr/local/daimoku-rails/app/models/simkey.rb'
require '/usr/local/daimoku-rails/app/models/simnorth.rb'
require '/usr/local/daimoku-rails/app/models/simsouth.rb'
require '/usr/local/daimoku-rails/app/models/simeast.rb'
require '/usr/local/daimoku-rails/app/models/simwest.rb'
require '/usr/local/daimoku-rails/app/models/simup.rb'
require '/usr/local/daimoku-rails/app/models/simdown.rb'
require '/usr/local/daimoku-rails/app/models/simmap.rb'
require '/usr/local/daimoku-rails/app/models/simplayer.rb'

require 'yaml'

# Used to process the scripts for all People, Places, and Things
module AutomationProcessor

  yaml = YAML.load_file '/usr/local/daimoku-server/database.yaml'
  @@connection = ActiveRecord::Base.establish_connection(yaml)

  # Initialize with the Simulation and PeerConnections
  # To read the state of the Simulation and disconnect Players
  # and reload the view of the Players (DejaVu) by inserting
  # a 'look' command in the Players connection stream
  #
  def initialize(box, peerconnections)
    @box = box
    @peerconnections = peerconnections
  end

  # Start the script processing
  def start_ticking
    @mover = Thread.new { tick }
    @mover.abort_on_exception = true
  end

end

# Process People scripts. People have no stats and usually perform day-to-day tasks or
# provide services to the Player (for example a Person can represent an FTP site)
class People
  include AutomationProcessor

  # Loop every 10 minutes
  def tick
    while true
      puts "Processing People"
      @box.eval("Simperson.process_people")
      sleep 600
    end
  end

end

# Process Character scripts. Characters have stats and can be NPCs
# An NPC usually has a script
class Characters
  include AutomationProcessor

  # Loop every 25 seconds
  def tick
    while true
      sleep 25
      puts "Processing Characters"
      sessionids = @box.eval("Simcharacter.process_characters(0, 100)")
      sessionids.each do |ss|
        sid = ss[0]
        health = ss[1]
        maxhealth = ss[2]
        @peerconnections.system_say(sid, "You feel better. [ +1/second  #{health}:#{maxhealth} ]")
      end
    end
  end
end

# Process Place scripts. Places are rooms. A room can be scripted.
class Places
  include AutomationProcessor

  # Loop every 10 minutes
  def tick
    while true
      puts "Processing Places"
      @box.eval("Simplace.process_places")
      #      places = Simplace.find(:all, :select => 'simpeople.script')
      #      begin
      #          @box.eval(thing.script) if thing.script
      #        rescue Sandbox::Exception, Sandbox::TimeoutError => e
      #            puts  e, "\n"
      #        end
      sleep 600
    end
  end
end


# Automates Thing actions within the Daimoku world.
# Calls Things.script every 10 mins, from within the sandbox
class Things
  include AutomationProcessor

  # Loop every 10 minutes
  def tick
    sleep 20
    while true
      print "."
      things = @box.eval %{
        Simthing.find(:all)
      }
      things.each do |thing|
        begin
          @box.eval(thing.script) if thing.script
        rescue Sandbox::Exception, Sandbox::TimeoutError => e
          puts  e, "\n"
        end
      end
      sleep 600
    end
  end

end


# Deletes the Simplayer if the Simcharacter hp goes to zero
#
class TheReaper

  include AutomationProcessor

  # Loop every 10
  def tick
    sleep 30
    puts "Starting to process the dead."
    while true
      sleep 10
      puts "Trying to find the dead."

      sessions = @box.eval %{
        Simcharacter.reap_dead_player_sessionids
      }
      p sessions
      sessions.each do |ss|
        puts "Disconnecting Player session #{ss}"
        @peerconnections.disconnect ss
      end

      @box.eval %{
        sess = Simcharacter.reap_dead_player_sessionids
        sess.each do |ss|
          s = Simplayer.find_by_sessionid(ss)
          next if !s

          Simperson.delete(s.simcharacters.first.simperson)
          Simcharacter.delete(s.simcharacters.first)
          s.reaped = true
          s.save!
          Simplayer.delete(s)
          s=nil
        end
      }
    end
  end
end
