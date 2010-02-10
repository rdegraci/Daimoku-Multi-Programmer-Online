# Matrix Extensions are classes that are instantiable by Players, while they are within the Simulation.

require 'socket'


# The HardLine class lets the Player import code into the Simulation
# imported code is stored into a String and any created Objects and classes
# are immediately available to all Players within the Simulation if the Classes have been
# made available by the Architect
#
# hardline = HardLine.new IORodneyAHSND1
# hardline.request 'http://somesite.com/ruby.rb'
# hardline.eval
# IORodneyAHSND1.puts hardline
#
class HardLine

  @@urls = []

  # Hide the Sandbox
  def self.sandbox= sb
    @@matrix =  sb
  end

  # Requests a URL
  def request url
    url.gsub!(/[\x00-\x09\x0B\x0C\x0E-\x1F\x80-\xFF]/,'') #no non printable characters
    @@urls << url

    #escape
    cooked = 'http://' + url
    @code = `curl #{url}`
    interface = @interface.to_s
    @code.gsub!('puts',"#{interface}.puts")  #replace external puts with the IO object
    @code.gsub!('all_symbols','class')  #no peeking at the symbol table
    puts "#{@code}"
  end

  # Evaluate the outside code
  def eval
    @@matrix.eval %"
    eval '#{@code}'
    "
  end

  # List the source code
  def list
    @interface.puts @code
  end

  # io is usually  the Player's IO object, for example IOjoe1827335
  def initialize io
    @interface = io
  end

  # prints out a history of URLs that have been accessed
  def history
    @@urls.each do |u|
      @interface.puts u
    end
  end

  def to_str
    @code
  end

  def to_s
    @code
  end

end


#
# An exception class used by SocketClient
#
class StopClient < StandardError
end

# Imported into the Simulation
#
# The handler class for the SocketClient class.
# The Player should implement on_input to set up any
# sort of client-side protocol that the Player would be interested in.
#
class SocketClientHandler

  # Called by SocketClient when input is detected on the socket
  # The Player should override this method if the Player wants to
  # create a Protocol.
  #
  # line     :    the text received from the socket
  #
  # What ever is returned from on_input should be a String
  def on_input line
    @io.puts line
    sleep 10
    "PONG"
  end

  # Initialize with the Player's IO object, for example:
  #
  # a = SocketClientHandler.new IOjoe128384H23
  #
  def initialize io
    @io = io
  end

end


# Referenced within the Simulation
#
# A line-oriented socket client.  This client uses a SocketClientHandler
#
#
# class MySocketClientHandler < SocketClientHandler
#   def on_input line
#     @io.puts line
#   end
# end
# a = MySocketClientHandler.new IOjoe234F84W
# b = SocketClient.new(a, '127.0.0.1', 2010)
#
class SocketClient

  # The matrix is the sandbox
  def self.sandbox= sb
    @@matrix =  sb
  end

  # Initialize with the Player's IO object
  def initialize(handler, url = '127.0.0.1' , port = 80, portoffset = 0)
    @handler = handler
    port = 80 if port != 2010
    port = 2010 if port != 80
    portoffset = 0 if portoffset < 0
    portoffset = 255 if portoffset > 255

    @client = TCPSocket.new(url, (port + portoffset))
    puts "Outbound SocketClient to #{url}"
    @acceptor = Thread.new do
      while true
        begin
          while @client.closed? == false do
            begin
              result = @client.gets.gsub(/[\x00-\x09\x0B\x0C\x0E-\x1F\x80-\xFF]/,'') #remove nonprintables
              puts result
              @client.puts(@handler.on_input(@client))
            rescue
              raise StopClient, "Error in SocketClient."
            end
          end
          puts "Closing socket connection."
          client.close if not client.closed?
          thread.abort_on_exception = true
        rescue StopClient
          @client.close if not @client.closed?
          break
        rescue Errno::ECONNABORTED
          puts "Remote Server socket abort. Closing socket."
          # client closed the socket even before accept
          @client.close if not @client.closed?
          break
        end
      end
    end
  end

end


# Imported into the Simulation
#
# The handler class for the SocketServer class.
# The Player should implement on_input to set up any
# sort of server-side protocol that the Player would be interested in
# implementing.
#
class SocketServerHandler

  # Called by SocketServer when input is received on the socket
  # The Player should override this method to implement any
  # sort of server-side protocol that the Player may be interested in.
  #
  #  ssh = SocketServerHandler.new IOjoe3845T23N
  #  ss = SocketServer.new ssh
  #
  # return: String
  #
  def on_input line
    @io.puts line
    sleep 10
    "PONG"
  end

  # Initialize with the Player's IO object, for example:
  #
  # ssh = SocketServerHandler.new IOjoe3845T23N
  #
  def initialize io
    @io = io
  end

end



require 'gserver'

#
# Socket Server internal representation
#
# This ChatServer klass is not available inside the Daimoku World.
# Instead, it is proxied via the SocketServer class.
class ChatServer < GServer

  def self.sandbox= sb
    @@sandbox = sb
  end

  def initialize(*args)
    super(*args)
    @handler = nil
  end

  def handler= h
    @handler = h
  end

  def serve(io)
    io.puts("Daimoku Online. Ready.")
    loop do
      # Every 5 seconds check to see if we are receiving any data
      if IO.select([io], nil, nil, 2)

        #remove nonprintable characters
        line = io.gets.gsub(/[\x00-\x09\x0B\x0C\x0E-\x1F\x80-\xFF]/,'')

        io.puts(@handler.on_input(line))
      end
    end

  end
end


# Referenced into the Simulation
#
# The SocketServer class is the high level class that allows
# the Player to create a line-oriented TCP server.
#
# The SocketServer will only listen on ports 2010 to 2260
#
#
class SocketServer

  @@socketservers = {}

  # Read access to the servers
  def self.servers
    @@socketservers
  end

  def randid
    abc = %{ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz}
    (1..20).map { abc[rand(abc.size),1] }.join
  end

  # The sandbox is the simulation
  def self.sandbox= sb
    @@matrix = sb
  end

  #
  # Initalize with an initialized SocketServerHandler
  #
  # port offset should be from 0 to 255
  #
  #  ssh = SocketServerHandler.new IOjoe3845T23N
  #  ss = SocketServer.new(ssh, 2010, 0)
  #  ss.start
  #
  #  To stop the SocketServer:
  #  ss.stop
  #
  def initialize(handler, port = 2010 , offset = 0)
    @port = port
    @port = 2010 if port != 2010
    @offset = offset
    @offset = 0 if offset < 0
    @offset = 255 if offset > 255
    @handler = handler
  end

  # Starts the socket server
  def start
    @server = ChatServer.new(@port + @offset)
    @server.handler = @handler
    @server.start
    @randid = randid
    @@socketservers[@randid] = @server
    nil
  end

  # Stops the Socket Server
  def stop
    @server.stop
    @server = nil
    @@socketservers[@randid] = nil
  end

end


