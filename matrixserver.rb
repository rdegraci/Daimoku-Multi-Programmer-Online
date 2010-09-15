#! /usr/local/bin/ruby
# /usr/local/lib/ruby/site_ruby/1.8/sandbox/server.rb

require 'sandbox/server'

require 'matrixirb.rb'
require 'architectirb.rb'
require 'agentirb.rb'
require 'npcirb.rb'

require 'support.rb'
require 'database.rb'
require 'simulationclient.rb'
require 'npcserver.rb'
require 'systemhub.rb'

# A socket server that accepts socket connections and assigns them to a SimulationClient on a
# per Thread basis. Uses a simple timer system to kill any SimulationClient that may be taking
# too long.
class SimulationServer < Sandbox::IRBServer

  @@simulation_clients = {}
  @@session_ids = {}

  CONFIG = YAML.load_file '/usr/local/daimoku-server/npc.yaml'

  # Initialize the Simulation, especially the Sandbox and the supporting
  # classes that make up the Daimoku system.
  def initialize(host, port, num_processors=(2**30-1), timeout=0)
    super(host, port, num_processors, timeout)

    puts "Bringing up sandbox."
    @sandbox = Sandbox.safe(:timeout => 20) #threads more than 20 seconds will time-out

    puts "Attaching sandbox to The Source."
    TheSource.sandbox = @sandbox

    puts "Attaching sandbox to The Matrix."
    TheMatrix.sandbox = @sandbox

    puts "Attaching sandbox to The System."
    TheSystem.sandbox = @sandbox

    puts "Referencing The System."
    @sandbox.ref TheSystem

    puts "Referencing The Source."
    @sandbox.ref TheSource

    puts "Initialize The Matrix."
    @matrix = TheMatrix.new

    puts "Instantiating Notification Hub"
    @notification_hub = SystemHubLoader.new(@sandbox)
    puts "Done."
    sleep 1

    puts "Instantiating TheReaper"
    @reaper = TheReaper.new(@sandbox, SimulationClient::peer_connections)
    @reaper.start_ticking
    puts "Done."
    sleep 1

    puts "Instantiating NPC Manager"
    @npcmanager = NPCManager.new("#{SimulationServer::CONFIG['sim']['server']}", "#{SimulationServer::CONFIG['sim']['port']}".to_i, @sandbox).run
    puts "Done."
    sleep 1

    puts "Starting People."
    @people = People.new(@sandbox, SimulationClient::peer_connections)
    #    @people.start_ticking
    sleep 1

    puts "Processing characters."
    @characters = Characters.new(@sandbox, SimulationClient::peer_connections)
    @characters.start_ticking
    sleep 1

    puts "Starting Things."
    @things = Things.new(@sandbox, SimulationClient::peer_connections)
    #   @things.start_ticking
    sleep 1

    puts "\n Simulation Ready!."
  end

  # Processes each socket connection. Normal clients are assigned the SimulationIRB.
  # The special 'architect' account is assigned the ArchitectIRB which has more functionality
  # for managing the Gameworld and system.
  def process_client(client)
    begin
      simulation_client = SimulationClient.new(client, @sandbox)
      if simulation_client.login?(client) == true
        @@simulation_clients[simulation_client.session_id] = simulation_client
        @@session_ids[simulation_client] = simulation_client.session_id
        case
        when simulation_client.name =~ /^[A]rchitect$/
          puts "Architect has logged in."
          mirb = ArchitectIRB.new @sandbox
          mirb.simulation_client = simulation_client
          mirb.start client
        when simulation_client.name =~ /^[A]gentSmith$/
          puts "Agent has logged in."
          mirb = AgentIRB.new @sandbox
          mirb.simulation_client = simulation_client
          mirb.start client
        when simulation_client.name =~ /^[A]gentJohnson$/
          puts "Agent has logged in."
          mirb = AgentIRB.new @sandbox
          mirb.simulation_client = simulation_client
          mirb.start client
        when simulation_client.name =~ /^[A]gentWilliams$/
          puts "Agent has logged in."
          mirb = AgentIRB.new @sandbox
          mirb.simulation_client = simulation_client
          mirb.start client
        when simulation_client.name =~ /^[K]eyMaker$/
          puts "Agent has logged in."
          mirb = NPCirb.new @sandbox
          mirb.simulation_client = simulation_client
          mirb.start client
        when simulation_client.name =~ /^Oracle$/
          puts "Agent has logged in."
          mirb = NPCirb.new @sandbox
          mirb.simulation_client = simulation_client
          mirb.start client
        when simulation_client.name =~ /^Seraph$/
          puts "Agent has logged in."
          mirb = NPCirb.new @sandbox
          mirb.simulation_client = simulation_client
          mirb.start client
        when simulation_client.name =~ /^Merovingian$/
          puts "Agent has logged in."
          mirb = NPCirb.new @sandbox
          mirb.simulation_client = simulation_client
          mirb.start client
        else
          mirb = SimulationIRB.new(@sandbox)
          mirb.simulation_client = simulation_client
          mirb.start(client)
        end
      end
    rescue EOFError,Errno::ECONNRESET,Errno::EPIPE,Errno::EINVAL,Errno::EBADF
      client.close unless client.closed?
    rescue Errno::EMFILE
      reap_dead_workers('too many files')
    rescue Object
      STDERR.puts "#{Time.now}: ERROR: #$!"
      STDERR.puts $!.backtrace.join("\n")
      client.puts "#{Time.now}: ERROR." if client.closed? == false && client
    ensure
      puts "Ensuring logout of #{simulation_client.name}"
      @@simulation_clients.delete simulation_client.session_id if simulation_client
      @@session_ids.delete simulation_client if simulation_client
      simulation_client.logout if simulation_client
      client.close unless client.closed?
      puts "#{simulation_client.name} logged out."
    end
  end


  # Runs the thing.  It returns the thread used so you can "join" it.  You can also
  # access the HttpServer::acceptor attribute to get the thread later.
  def run

    BasicSocket.do_not_reverse_lookup=true
    @sandbox.eval "Simplayer.reset_online_status"

    @acceptor = Thread.new do
      while true
        begin
          client = @socket.accept
          worker_list = @workers.list

          if worker_list.length >= @num_processors
            STDERR.puts "Server overloaded with #{worker_list.length} processors (#@num_processors max). Dropping connection."
            client.close
            reap_dead_workers("max processors")
          else
            thread = Thread.new { process_client(client) }
            thread.abort_on_exception = true
            thread[:started_on] = Time.now
            @workers.add(thread)

            sleep @timeout/100 if @timeout > 0
          end
        rescue StopServer
          @socket.close if not @socket.closed?
          break
        rescue Errno::EMFILE
          reap_dead_workers("too many open files")
          sleep 0.5
        rescue Errno::ECONNABORTED
          # client closed the socket even before accept
          client.close if not client.closed?
        end
      end

      graceful_shutdown
    end

    return @acceptor
  end

end


