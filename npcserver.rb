require 'drb'
require 'hub.rb'
require 'yaml'

require '/usr/local/daimoku-rails/app/models/simplayer.rb'

# Used to connect the Agent to the notification system and to log the Agent into the System
module AgentNotification

  CONFIG = YAML.load_file '/usr/local/daimoku-server/npc.yaml'

  # Agents use Distributed Ruby to send/recieve messages to each other and the System
  def connect_to_hub
    puts "Connecting to Notification Hub #{CONFIG['hub']['server']}:#{CONFIG['hub']['port']}"
    @hub = DRbObject.new(nil, "druby://#{CONFIG['hub']['server']}:#{CONFIG['hub']['port']}")
    puts "Connected!"
  end

  # Connects to the simulation.
  def connect_to_simulation(name, password)
    puts "Connectin to Simulation"
    begin
      @server = TCPSocket.open("#{CONFIG['sim']['server']}", "#{CONFIG['sim']['port']}".to_i)
      puts "Talking with Server..."
      puts @server.gets  #splash
      puts @server.gets  #blank
      @server.puts name
      puts @server.gets #welcome message and password request
      @server.puts password
      puts "Connected!"
    rescue
      @server = nil
    end
  end
end

# By using a Module, the System can create a Person within the Simulation and turn them into an Agent
# or the System can take an existing Person, within the Simulation, and turn them into an Agent
#
module LeadAgent

  # The runloop of the Agent Smith
  def runloop
    config = YAML.load_file '/usr/local/daimoku-server/npc.yaml'
    puts "Entering Agent Smith Run Loop"
    @attack_target = ""

    while true
      if @server == nil then
        puts "Attempting to reconnect Agent Smith to Simulation"
        sleep 5
        connect_to_simulation("#{config['smith']['username']}", "#{config['smith']['password']}")
      end
      begin
        eval %{
          #{config['leadagent']['script']}
        }
      rescue
        puts "Error in the LeadAgent script, reconnecting in 10 seconds"
        @server = nil
        sleep 10
        break
      end

      if @hub.warn.empty? == false then
        puts "Lead Agent responding to: #{@hub.warn}"
        case
        when true
          simulation_client = @hub.simulation_client
          target_session_id = simulation_client.session_id

          puts "Agent found sessionid of #{target_session_id}"

          target_player = Simplayer.find_by_sessionid target_session_id
          if (target_player == nil || target_player.online == false) then
            @attack_target = ""
            @hub.clear_warning
          else

            p target_player

            agent_smith = Simplayer.find_by_name("#{config['smith']['username']}")
            p agent_smith

            target_character = target_player.simcharacters.first
            agent_character = agent_smith.simcharacters.first

            if (target_character.simperson.simplace.simpeople.include?(agent_character.simperson) ==false) then
              target_character.simperson.simplace.simpeople << agent_character.simperson

              agent_character.simperson.save!
              target_character.simperson.simplace.save!

              @server.puts "AgentTeleport #{target_character.simperson.simplace.uniqueid}"
              @server.puts "say Mr #{target_character.name} we meet again"
              @server.puts "AgentPunch #{target_character.name}"
              @attack_target = target_character.name
              sleep 2
            end
            if (target_character.simperson.simplace.simpeople.include?(agent_character.simperson) == true) then
              @server.puts "AgentPunch #{target_character.name}"
              @attack_target = target_character.name
              sleep 3
            end
            if (target_character.simperson.simplace.simpeople.include?(agent_character.simperson) ==false) then
              @attack_target = ""
              @hub.clear_warning
            end
          end
        end
      end

      if @hub.info.empty? == false then
      end

      if @hub.fatal.empty? == false then
      end

      puts "#{Time.now} Agent Smith: #{@hub.warn}"  if @hub.warn.empty? == false
      puts "#{Time.now} Agent Smith: #{@hub.info}"  if @hub.info.empty? == false
      puts "#{Time.now} Agent Smith: #{@hub.fatal}"  if @hub.fatal.empty? == false
      sleep 10
    end
  end
end

module AssistantAgent

  def runloop
    config = YAML.load_file '/usr/local/daimoku-server/npc.yaml'
    while true
      if @server == nil then
        puts "Attempting to reconnect Agent Johnson to Simulation"
        connect_to_simulation("#{config['smith']['username']}", "#{config['smith']['password']}")
      end
      begin
        eval %{
          #{config['assistantagent']['script']}
        }
      rescue
        puts "Error in the Assistant Agent script, reconnecting in 10 seconds"
        @server = nil
        sleep 10
        break
      end
      puts "#{Time.now} Agent Johnson: #{@hub.warn}"  if @hub.warn.empty? == false
      puts "#{Time.now} Agent Johnson: #{@hub.info}"  if @hub.info.empty? == false
      puts "#{Time.now} Agent Johnson: #{@hub.fatal}"  if @hub.fatal.empty? == false
      sleep 10
    end
  end
end

module SpecialAgent

  def runloop
    config = YAML.load_file '/usr/local/daimoku-server/npc.yaml'
    while true
      if @server == nil then
        puts "Attempting to reconnect Agent Williams to Simulation"
        connect_to_simulation("#{config['smith']['username']}", "#{config['smith']['password']}")
      end
      begin
        eval %{
          #{config['specialagent']['script']}
        }
      rescue
        puts "Error in the Special Agent script, reconnecting in 10 seconds."
        @server = nil
        sleep 10
        break
      end
      puts "#{Time.now} Agent Williams: #{@hub.warn}" if @hub.warn.empty? == false
      puts "#{Time.now} Agent Williams: #{@hub.info}"  if @hub.info.empty? == false
      puts "#{Time.now} Agent Williams: #{@hub.fatal}"  if @hub.fatal.empty? == false
      sleep 10
    end
  end
end

# Smith is the name, Agent Smith
class Smith
  CONFIG = YAML.load_file '/usr/local/daimoku-server/npc.yaml'
  include AgentNotification
  include LeadAgent
  def initialize
    connect_to_hub
    connect_to_simulation("#{CONFIG['smith']['username']}", "#{CONFIG['smith']['password']}")
  end
end

# Johnson is the name, Agent Johnson
class Johnson
  CONFIG = YAML.load_file '/usr/local/daimoku-server/npc.yaml'
  include AgentNotification
  include AssistantAgent
  def initialize
    connect_to_hub
    connect_to_simulation("#{CONFIG['johnson']['username']}", "#{CONFIG['johnson']['password']}")
  end
end

# Williams is the name, Agent Williams
class Williams
  CONFIG = YAML.load_file '/usr/local/daimoku-server/npc.yaml'
  include AgentNotification
  include SpecialAgent
  def initialize
    connect_to_hub
    connect_to_simulation("#{CONFIG['williams']['username']}", "#{CONFIG['williams']['password']}")
  end
end


# NPCManager manages the runloops of the NPCs. Each NPC is threaded.
class NPCManager

  # initialize the NPCManager
  def initialize(host, port, sandbox)
    DRb.start_service
    puts "Started Drb!"

    # Only use to make NPC thing objects available.
    # Do not use to change the Simulation state!
    @sandbox = sandbox
  end

  # Create the NPCs and start their runloops
  def run
    sleep 5
    @acceptor = Thread.new do
      puts "Starting Agents"
      a = Thread.new { @smith = Smith.new ; @smith.runloop }
      a.abort_on_exception = true
      #b = Thread.new { @johnson = Johnson.new ; @johnson.runloop }
      #b.abort_on_exception = true
      #c = Thread.new { @williams = Williams.new ; @williams.runloop }
      #c.abort_on_exception = true
      while true
        sleep 5
        print "."
      end
    end
    @acceptor.abort_on_exception = true
    return @acceptor
  end
end




