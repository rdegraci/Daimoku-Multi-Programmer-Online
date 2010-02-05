require 'rubygems'
require 'active_record'
require 'active_support'

require '../daimoku-rails/app/models/simcharacter.rb'
require '../daimoku-rails/app/models/simperson.rb'
require '../daimoku-rails/app/models/simplace.rb'
require '../daimoku-rails/app/models/simthing.rb'
require '../daimoku-rails/app/models/simdoor.rb'
require '../daimoku-rails/app/models/simkey.rb'
require '../daimoku-rails/app/models/simnorth.rb'
require '../daimoku-rails/app/models/simsouth.rb'
require '../daimoku-rails/app/models/simeast.rb'
require '../daimoku-rails/app/models/simwest.rb'
require '../daimoku-rails/app/models/simup.rb'
require '../daimoku-rails/app/models/simdown.rb'
require '../daimoku-rails/app/models/simmap.rb'
require '../daimoku-rails/app/models/simplayer.rb'

require 'yaml'

# Used to process the scripts for all People, Places, and Things
module AutomationProcessor

  yaml = YAML.load_file 'database.yaml'
  @@connection = ActiveRecord::Base.establish_connection(yaml)
        
  # Initialize with the Simulation
  def initialize box
    @box = box
  end

  # Start the script processing
  # TODO: Thread this
  def start_ticking
    Thread.abort_on_exception = false
    @mover = Thread.new { tick }
  end

end

# Process People scripts. People have no stats and usually perform day-to-day tasks or
# provide services to the Player (for example a Person can represent an FTP site)
class People
  include AutomationProcessor
  
  # Loop every 10 minutes
  def tick
    sleep 10
    while true
      puts "Processing People"
      people = Simperson.find(:all, :select => 'simpeople.script')
      people.each do |aperson|
        begin
          @box.eval(aperson.script) if aperson.script
	      rescue Sandbox::Exception, Sandbox::TimeoutError => e
            puts  e, "\n"
        end
      end
      sleep 600
    end
  end

end

# Process Character scripts. Characters have stats and can be NPCs
# An NPC usually has a script
class Characters
  include AutomationProcessor

  # Loop every 10 minutes
  def tick
    sleep 10
    while true
      puts "Processing Characters" 
      chars = Simcharacter.find(:all, :conditions => ['hitpoints < ?', 100])
      chars.each do |cc|
        begin
          health = cc.hitpoints
          health = health + 5
          health = 100 if health > 100
          cc.health = health
          cc.save!
        rescue
	        puts "Error trying to process Characters" 
        end
      end
      sleep 10
    end
  end

end

# Process Place scripts. Places are rooms. A room can be scripted.
class Places
  include AutomationProcessor

  # Loop every 10 minutes
  def tick
    sleep 10
    while true
      puts "Processing Places"
      places = Simplace.find(:all, :select => 'simpeople.script')
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
    sleep 10
    while true
      print "."
      things = Simthing.find(:all)
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






  



    
