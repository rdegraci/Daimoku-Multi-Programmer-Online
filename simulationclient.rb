require 'characterproxy.rb'
require 'peerconnections.rb'
require 'yaml'
require 'digest/sha1'


# The SimulationClient handles the login of the Player and also creates the
# various Objects that the Player uses for IO, for the Simulation to use for output to
# the Player, and for the CharacterProxy object which serves as the proxy to the Simulation.
class SimulationClient

  attr_reader :name, :password, :socket, :session_id, :character_proxy, :player_io, :player_lego_io

  config = YAML.load_file '/usr/local/daimoku-server/database.yaml'
  @@connection = ActiveRecord::Base.establish_connection(config)

  @@peers = PeerConnections.new

  # Other parts of the system will need access to the peer simulation clients
  # to send output to the clients via their sockets
  def self.peer_connections
    @@peers
  end

  # Initialize the SimulationClient
  def initialize(socket, sandbox)
    @sandbox = sandbox
    @socket = socket
    @io_id = randnum
    @lego_id = randnum
    @matrix_character_ref = ""
    @matrix_character_io = ""
    @player_io = ""
    @matrix_character = ""
    @player_session = ""
  end

  # Login the Player and create the game Objects. The game Objects are needed
  # to provide Player IO, to provide a way for the Matrix to send output to the
  # Player, and for the CharacterProxy to interface to the Matrix.
  def login? socket
    logininfo = query socket
    if logininfo
      @matrix_character_io = "MCIO_#{@session_id}"
      build_matrix_io_object
      puts "Creating simulation IO object: #{@matrix_character_io}"

      @matrix_character = "CH_#{@session_id}"
      @matrix_character_ref = "ref#{@session_id}"
      build_character_object
      puts "Creating simulation Character object #{@matrix_character}."

      # Interface to the database
      @character_proxy = CharacterProxy.new(@name, @matrix_character_ref, @sandbox, @socket, @matrix_character_io, @session_id, self)
      @character_proxy.login

      @player_io = "PIO_#{name}_#{@io_id}"
      build_player_io_object @character_proxy
      puts "Creating simulation Player IO object #{@player_io}."

      @character_proxy.look

      @character_proxy.announce_arrival
      true
    else
      false
    end
  end

  # Called by the CharacterProxy, as part of clean up when
  # a Player is reaped.
  def system_cleanup
    @sandbox.eval %{
      #{@matrix_character_ref} = nil
      #{@matrix_character_io} = nil
      #{@player_io} = nil
      #{@matrix_character} = nil
      #{@player_session} = nil
    }
  end


  # Called by the SimulationServer when this SimulationClient exits
  def logout
    @character_proxy.logout if @character_proxy
  end

  # Creates a random alphanumeric string. Uses as part of the session id of
  # the Player.
  def randid
    abc = %{ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz}
    (1..20).map { abc[rand(abc.size),1] }.join
  end

  # Creates a random alphanumeric string. Uses as a local variable
  def randid_lc
    abc = %{abcdefghijklmnopqrstuvwxyz}
    (1..20).map { abc[rand(abc.size),1] }.join
  end

  # Creates a random alphanumeric number.
  # Used as part of the naming of the player's IO object
  def randnum
    abc = %{123456789ABCDEFGHIJKLMNPQRSTUVWXYZ123456789}
    result = (1..43).map { abc[rand(abc.size),1] }.join
    result.slice(1,8)
  end

  # The login process. Returns nil if the login fails.
  def query client
    client.puts "Daimoku: Multi-Programmer Online v0.3"
    client.puts
    client.print "Type your name [alpha numeric only] :"

    name = client.gets
    return nil if !name
    name.chomp!
    name.gsub!(/[\x00-\x09\x0B\x0C\x0E-\x1F\x80-\xFF]/,'')
    return nil if name =~ /\W+/
    return nil if name == ""
    name.gsub!(/ /,"_")        #no spaces

    puts "Login detected."

    id = randid

    player = nil
    character =nil

    @player_session = "PLS_#{id}"
    puts "Creating player session #{@player_session}"

    player = @sandbox.eval %{
      Simplayer.find(:first, :conditions => ['name = ?', '#{name}'])
    }

    if player == nil then
      client.puts
      client.print "Do you want to create a new account? [y/Quit] :"
      new_acct = client.gets
      return nil if !new_acct
      new_acct.chomp!
      new_acct.gsub!(/[\x00-\x09\x0B\x0C\x0E-\x1F\x80-\xFF]/,'')
      return nil if new_acct =~ /\W+/
      return nil if new_acct == ""
      if new_acct =~ /^[Yy]/ then
        client.puts "OK."
      else
        return nil
      end

      client.puts
      client.puts "Ready to create new account for user #{name}"
      client.puts

      client.print "Enter a password (alpha numeric only) :"
      password = client.gets
      return nil if !password
      password.chomp!
      password.gsub!(/[\x00-\x09\x0B\x0C\x0E-\x1F\x80-\xFF]/,'')
      return nil if password =~ /\W+/
      return nil if password == ""
      password.gsub!(/ /,"")        #no spaces

      encrypted_password = Digest::SHA1.hexdigest(password)

      password_session = "#{randid_lc}#{id}"
      @sandbox.eval %{
        name = '#{name}'
        #{password_session} = '#{encrypted_password}'
        #{@player_session} = Simplayer.make_name(name, #{password_session})
        name = nil
        #{password_session} = nil
      }
      puts "New Account: #{name}"

      @name = name
      @password = password
      @session_id = id
    else
      puts "Return Account: #{name}"

      client.puts "Welcome back #{name}."
      client.print "Enter your password :"
      password = client.gets
      return nil if !password
      password.chomp!
      password.gsub!(/[\x00-\x09\x0B\x0C\x0E-\x1F\x80-\xFF]/,'')
      return nil if password =~ /\W+/
      return nil if password == ""
      password.gsub!(/ /,"")        #no spaces

      encrypted_password = Digest::SHA1.hexdigest(password)

      if encrypted_password != player.password then
        return nil
      else
        @name = name
        @password = encrypted_password
        @session_id = id
      end
    end
  end

  # Builds the IO Object to handle messages from the Matrix to the Player
  def build_matrix_io_object

    puts "Begin evaluating Matrix IO Object MCIO"

    # Create an IO klass so that we can write to the Player's socket from within the sandbox
    # as well as the ability to send messages to/fromm the Players peers
    Kernel::eval( %{
      class MCIO_#{@session_id}
        @@client = nil
        @@peers = nil

        def self.client cli
          @@client = cli
        end

        def self.peers others
          @@peers = others
        end

        def self.session_id id
          @@session_id = id
        end

        # Message to all Players
        def self.shout text
          #user @@peers to send this message to everyone
        end

        # Message to certain Players
        def self.tell(text, sessions )
          #use @@peers to send text to sessionids
          sessions.each do |s|
            @@peers.say_private(s, text) if s != @@session_id && s
          end
        end

        # To the Player's cosole
        def self.puts *a
          @@client.puts(*a) if @@client
        end

        def self.print *a
          @@client.print(*a) if @@client
        end

      end
    },TOPLEVEL_BINDING)
    puts "Completed evaluating MCIO class"

    puts 'Referencing the MCIO within the Simulation'

    # Reference the IO klass so that it exists within the sandbox
    # and setup the output socket and the access to the peer player sockets
    eval %{
      @sandbox.ref MCIO_#{@session_id}
      MCIO_#{@session_id}.client @socket
      MCIO_#{@session_id}.peers @@peers
      MCIO_#{@session_id}.session_id @session_id
    }

    puts "Completed referencing the MCIO"

  end

  # Builds the Character object, used inside the Matrix as to manipulate
  # and query the database.
  def build_character_object
    # Connect the dynamically created variable to the Character activerecord class
    @sandbox.eval %{
      #{@matrix_character_io}.print "Instantiating....."
      name = '#{@name}'
      #{@matrix_character_ref} = Simcharacter.find(:first, :conditions => ['name = ?', name])
      #{@matrix_character_io}.puts #{@matrix_character_ref}.name
      #{@matrix_character_io}.puts " Done!"
    }
  end

  # Builds the Player's IO object. The Player needs an IO object because Kernel.puts is not
  # available while inside the Matrix
  def build_player_io_object character_proxy
    Kernel::eval( %{
      class PIO_#{@name}_#{@io_id}
        @@socket = nil
        @@character_proxy = nil

        def self.socket= cli
          @@socket = cli
        end

        def self.character_proxy= mp
          @@character_proxy = mp
        end

        def self.puts *a
          @@socket.puts *a
        end

        def self.print *a
          @@socket.print  *a
        end

        #actions

        def self.look
          @@character_proxy.look
        end

        def self.exits
          @@character_proxy.exits
        end

        def self.north
          @@character_proxy.north
        end

        def self.south
          @@character_proxy.south
        end

        def self.east
          @@character_proxy.east
        end

        def self.west
          @@character_proxy.west
        end

        def self.up
          @@character_proxy.up
        end

        def self.down
          @@character_proxy.down
        end

        def self.say text
          @@character_proxy.say_room text
        end

        # Important, called by a Builder, to interface to the World Database safely
        def self.character_name
          @@character_proxy.name
        end

      end
    },TOPLEVEL_BINDING)

    raise if !@socket
    raise if !character_proxy

    eval %{
      @sandbox.ref PIO_#{@name}_#{@io_id}
      PIO_#{@name}_#{@io_id}.socket = @socket
      PIO_#{@name}_#{@io_id}.character_proxy = character_proxy
    }
    @socket.puts "Creating object PIO_#{@name}_#{@io_id} for IO. i.e. PIO_#{@name}_#{@io_id}.puts 'hello world'"

    character_proxy.io_object_name = "PIO_#{@name}_#{@io_id}"


    #Create LEGO class which will allow Builders, that players create, to interface to the World Database safely
    Kernel::eval( %{
      class LEGO#{@name}#{@lego_id}
        @@socket = nil
        @@character_proxy = nil

        def self.socket= cli
          @@socket = cli
        end

        def self.character_proxy= mp
          @@character_proxy = mp
        end

        def self.puts *a
          @@socket.puts *a
        end

        def self.print *a
          @@socket.print  *a
        end
      end

      # Important, called by a Builder, to interface to the World Database safely
      def self.character_name
        @@character_proxy.name
      end
    }, TOPLEVEL_BINDING)

    eval %{
      @sandbox.ref LEGO#{@name}#{@lego_id}
      LEGO#{@name}#{@lego_id}.socket = @socket
      LEGO#{@name}#{@lego_id}.character_proxy = character_proxy
    }
    @player_lego_io = "LEGO#{@name}#{@lego_id}"
    @socket.puts "Creating object LEGO#{@name}#{@lego_id} for extensions . i.e. h = HardLine.new(LEGO#{@name}#{@lego_id})"

  end

  # The following methods are called by the SimulationIRB, to implement a simple commandline interface
  # by letting the SimulationIRB directly manipulate the CharacterProxy

  # Called by the SimulationIRB, for sharing code
  def say_code code
    @character_proxy.say_code(code)
  end

  # Called by the SimulationIRB, for looking around
  def look
    @character_proxy.look
  end

  # Called by the SimulationIRB, for cataloging inventory
  def inventory
    @character_proxy.inventory
  end

  # Called by the SimulationIRB, for listing exits
  def exits
    @character_proxy.exits
  end

  # Called by the SimulationIRB, for going north
  def north
    @character_proxy.north
  end

  # Called by the SimulationIRB, for going south
  def south
    @character_proxy.south
  end

  # Called by the SimulationIRB, for going east
  def east
    @character_proxy.east
  end

  # Called by the SimulationIRB, for going west
  def west
    @character_proxy.west
  end

  # Called by the SimulationIRB, for going up
  def up
    @character_proxy.up
  end

  # Called by the SimulationIRB, for going down
  def down
    @character_proxy.down
  end

  # Called by the SimulationIRB, for getting the IO object name
  def io
    @character_proxy.io
  end

  # Called by the SimulationIRB, for speaking to the room
  def say text
    @character_proxy.say_room text
  end

  # Called by the SimulationIRB, for emoting to the room
  def emote text
    @character_proxy.emote_room text
  end

  # Called by the SimulationIRB, for taking an object
  def take name
    @character_proxy.take name
  end

  # Called by the SimulationIRB, for dropping an object
  def drop name
    @character_proxy.drop name
  end

  # Called by the Agent IRB
  def punch name
    # Agents are maxed at 25 points of damage, per punch
    @character_proxy.agent_punch(name, 25)
  end

  # Called by the Agent IRB
  def teleport room_uniqueid
    #Teleport was handled by NPCManager, therefore the Agent just announces its arrival
    @character_proxy.announce_arrival
  end

end


