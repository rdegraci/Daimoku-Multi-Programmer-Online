
require 'simulationclient.rb'

# CharacterProxy acts as the proxy between the Daimoku Game World and the SimulationClient.
# Commands are evaluated within the Sandbox and then the result marshalled back to the CharacterProxy.
class CharacterProxy

  attr_reader :name, :matrix_character, :sandbox, :socket, :character_matrix_io, :session_id

  attr_writer :io_object_name

  # character_matrix_io is used by the Sandbox to send output back to the Player's socket
  def initialize(name, matrix_character, sandbox, socket, character_matrix_io, session_id, simulation_client)
    @matrix_character = matrix_character
    @sandbox = sandbox
    @socket = socket
    @characterio = character_matrix_io
    @session_id = session_id
    @io_object_name = ""

    #There must be a better way
    @peers = SimulationClient::peer_connections
    raise if !@peers

    #Used to clean up the simulation client
    #When the System forces a Player deletion
    @simulation_client = simulation_client

    @name = name
  end

  # Provide a random string, used for creating session ids and guids
  def randnum
    abc = %{123456789ABCDEFGHIJKLMNPQRSTUVWXYZ123456789}
    result = (1..43).map { abc[rand(abc.size),1] }.join
    result.slice(1,8)
  end

  # Look around the current Room. Called by the SimulationClient
  def look
    look_around = @sandbox.eval %{
      name = '#{@name}'
      #{@matrix_character} = Simcharacter.find(:first, :conditions => ['name = ?', name], :include => [{:simperson => :simplace}])
      #{@matrix_character}.look
    }
    @socket.puts
    @socket.puts
    @socket.puts look_around.first
    @socket.puts
    @socket.puts look_around.last

    look_around = @sandbox.eval %{
      name = '#{@name}'
      #{@matrix_character} = Simcharacter.find(:first, :conditions => ['name = ?', name], :include => [{:simperson => :simplace}])
      #{@matrix_character}.room_occupants #{@characterio}
      #{@matrix_character}.room_items #{@characterio}
    }
  end

  # Called by the SimulationServer, when the Character is logging into the GameWorld
  def login
    puts "matrix character is #{@matrix_character}"
    puts "#{@matrix_character.class}"
    puts "Saving sessionid #{@session_id} into Simplayer"
    @sandbox.eval %{
      name = '#{@name}'
      #{@matrix_character} = Simcharacter.find(:first, :conditions => ['name = ?', name], :include => [:simplayer])
      #{@matrix_character}.simplayer.online = true;
      #{@matrix_character}.simplayer.sessionid = "#{@session_id}"
      #{@matrix_character}.simplayer.save!
    }
    @peers.add self
  end

  # Called by the SimulationServer, when the Character is logging out of the GameWorld
  def logout
    puts "matrix_character is #{@matrix_character}"
    puts "#{@matrix_character.class}"

    @sandbox.eval %{
      name = '#{@name}'
      #{@matrix_character} = Simcharacter.find(:first, :conditions => ['name = ?', name], :include => [:simplayer])
      #{@matrix_character}.logout if #{@matrix_character} != nil
    }

    @peers.remove self
  end

  # Called by TheReaper to force logout a dead Player
  def system_logout
    puts "matrix_character is #{@matrix_character}"
    puts "#{@matrix_character.class}"

    @sandbox.eval %{
      name = '#{@name}'
      #{@matrix_character} = Simcharacter.find(:first, :conditions => ['name = ?', name], :include => [:simplayer])
      #{@matrix_character}.logout
    }

    @simulation_client.system_cleanup

    #Clean up the
    @sandbox.eval %{
      #{@matrix_character} = nil
      #{@characterio} = nil
    }

    @peers.remove self

    begin
      #closing the socket will always generate an error
      @socket.close
    rescue
      puts "Force close socket of Player:#{@name}"
    end

  end

  # Describe exits from the current Room. Called by the SimulationClient
  def exits
    ways_out = @sandbox.eval %{
      name = '#{@name}'
      #{@matrix_character} = Simcharacter.find(:first, :conditions => ['name = ?', name], :include => [{:simperson => :simplace}])
      #{@matrix_character}.exits
    }
    puts "ways out:"
    p ways_out
    if ways_out.size != 0 then
      @socket.puts
      @socket.print "Ways out: "

      ways_out.each do |e|
        @socket.print " #{e} "
      end

      @socket.puts
      @socket.puts
    else
      @socket.puts
      @socket.puts "There is no way out of here."
      @socket.puts
      @socket.puts
    end
  end

  # Go to the room North of the current Room. Called by the SimulationClient
  def north
    puts "#{@matrix_character} going north."
    @sandbox.eval %{
      name = '#{@name}'
      #{@matrix_character} = Simcharacter.find(:first, :conditions => ['name = ?', name], :include => [{:simperson => :simplace}])
      #{@matrix_character}.go(:simnorth, #{@characterio})
    }
  end

  # Go to the room South of the current Room. Called by the SimulationClient
  def south
    puts "#{@matrix_character} going south."
    @sandbox.eval %{
      name = '#{@name}'
      #{@matrix_character} = Simcharacter.find(:first, :conditions => ['name = ?', name], :include => [{:simperson => :simplace}])
      #{@matrix_character}.go(:simsouth, #{@characterio})
    }
  end

  # Go to the room East of the current Room. Called by the SimulationClient
  def east
    puts "#{@matrix_character} going east."
    @sandbox.eval %{
      name = '#{@name}'
      #{@matrix_character} = Simcharacter.find(:first, :conditions => ['name = ?', name], :include => [{:simperson => :simplace}])
      #{@matrix_character}.go(:simeast, #{@characterio})
    }
  end

  # Go to the room West of the current Room. Called by the SimulationClient
  def west
    puts "#{@matrix_character} going west."
    @sandbox.eval %{
      name = '#{@name}'
      #{@matrix_character} = Simcharacter.find(:first, :conditions => ['name = ?', name], :include => [{:simperson => :simplace}])
      #{@matrix_character}.go(:simwest, #{@characterio})
    }
  end

  # Go to the room above the current Room. Called by the SimulationClient
  def up
    puts "#{@matrix_character} going up."
    @sandbox.eval %{
      name = '#{@name}'
      #{@matrix_character} = Simcharacter.find(:first, :conditions => ['name = ?', name], :include => [{:simperson => :simplace}])
      #{@matrix_character}.go(:simup, #{@characterio})
    }
  end

  # Go to the room below the current Room. Called by the SimulationClient
  def down
    puts "#{@matrix_character} going down."
    @sandbox.eval %{
      name = '#{@name}'
      #{@matrix_character} = Simcharacter.find(:first, :conditions => ['name = ?', name], :include => [{:simperson => :simplace}])
      #{@matrix_character}.go(:simdown,  #{@characterio})
    }
  end

  # Announce the Player's arrival, to other Players within the current Room. Called by the SimulationClient
  def announce_arrival
    @sandbox.eval %{
      name = '#{@name}'
      #{@matrix_character} = Simcharacter.find(:first, :conditions => ['name = ?', name], :include => [{:simperson => :simplace}])
      #{@matrix_character}.announce_arrival #{@characterio}
    }
  end

  # Announce the name of the IO Object. Called by the SimulationClient
  def io
    @socket.puts "Your IO object is #{@io_object_name}"
  end

  # Say a message to the current room
  # Send the message to each Player's socket
  def say_room text
    cooked_text = "\n#{@name} says, #{text}"
    sessions = @sandbox.eval %{
      name = '#{@name}'
      #{@matrix_character} = Simcharacter.find(:first, :conditions => ['name = ?', name], :include => [{:simperson => :simplace}])
      #{@matrix_character}.current_room_sessionids
    }
    sessions.each do |s|
      @peers.say_private(s, cooked_text) if s != @session_id
    end

    @socket.puts "You say, #{text}"
  end

  # Agent Punch a Player, oh yeah!
  def agent_punch(name, damage)
    @target_punch = name
    @damage = damage

    cooked_text = "\n#{@name} punches #{@target_punch} in the face, with his fist. [ Damage: -#{@damage/5} ]"
    sessions = @sandbox.eval %{
      name = '#{@target_punch}'
      #{@matrix_character} = Simcharacter.find(:first, :conditions => ['name = ?', name], :include => [{:simperson => :simplace}])
      current_hp = #{@matrix_character}.hp
      current_hp = current_hp - #{@damage}
      #{@matrix_character}.hp = current_hp
      #{@matrix_character}.hp = 0 if #{@matrix_character}.hp < 1
      #{@matrix_character}.save!

      # Add the target session as the last element
      watching = #{@matrix_character}.current_room_sessionids +  Array.new.<<(#{@matrix_character}.simplayer.sessionid)
    }

    # Tell players in the room of the action, except for the Agent and the Target
    sessions.each do |s|
      @peers.say_private(s, cooked_text) if (s != @session_id) && (s != sessions.last)
    end

    cooked_text = "\n#{@name} punches _you_ in the face, with his fist! [ Damage: -#{damage} ]"
    @peers.say_private(sessions.last, cooked_text)
    @socket.puts "You punch, #{@target_punch} for #{damage} points of damage"
  end


  # Emote a message to the current room
  # Send the message to each Player's socket
  def emote_room text
    cooked_text = "\n#{@name} #{text}"
    sessions = @sandbox.eval %{
      name = '#{@name}'
      #{@matrix_character} = Simcharacter.find(:first, :conditions => ['name = ?', name], :include => [{:simperson => :simplace}])
      #{@matrix_character}.current_room_sessionids
    }
    sessions.each do |s|
      @peers.say_private(s, cooked_text) if s != @session_id
    end
  end

  # Take an item that is in the current room
  # Send the message to each Player's socket
  def take item
    taken = @sandbox.eval %{
      item_name = '#{item}'
      name = '#{@name}'
      #{@matrix_character} = Simcharacter.find(:first, :conditions => ['name = ?', name], :include => [{:simperson => :simplace}])
      room_id = #{@matrix_character}.simperson.simplace_id
      thing = Simthing.find(:first, :conditions => ['name = ? & simplace_id = ?', item_name, room_id])
      if thing then
        #{@matrix_character}.simperson.simthings << thing
        thing.simplace_id = nil
        thing.save!
        #{@matrix_character}.save!
        #{@characterio}.puts "You take the #{item}."
        true
      else
        false
      end
    }
    emote_room "#{@name} takes the #{item}." if taken == true
  end

  # Drop an items into the current room
  # Send the message to each Player's socket
  def drop item
    raise if !@characterio
    dropped = @sandbox.eval %{
      name = '#{@name}'
      item_name = '#{item}'
      #{@matrix_character} = Simcharacter.find(:first, :conditions => ['name = ?', name], :include => [{:simperson => :simthings}])
      #{@matrix_character}.drop(item_name, #{@characterio})
    }
    emote_room "#{@name} drops the #{item}." if dropped == true
  end

  # Drop an items into the current room
  # Send the message to each Player's socket
  def inventory
    raise if !@characterio
    @sandbox.eval %{
      name = '#{@name}'
      #{@matrix_character} = Simcharacter.find(:first, :conditions => ['name = ?', name], :include => [{:simperson => :simthings}])
      #{@matrix_character}.inventory(name, #{@characterio})
    }
  end


  # Say the code and it's results to the current room.
  # Send the code to each Player's socket.
  def say_code code
    cooked_text = "\n#{@name}: #{code}"
    sessions = @sandbox.eval %{
      name = '#{@name}'
      #{@matrix_character} = Simcharacter.find(:first, :conditions => ['name = ?', name], :include => [{:simperson => :simplace}])
      #{@matrix_character}.current_room_sessionids
    }
    sessions.each do |s|
      @peers.say_private(s, cooked_text) if s != @session_id
    end
  end

end


