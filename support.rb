# Support classes are used by the SimulationServer to create the overall System. These classes may be available to Agents or Neo
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
require 'matrix-extensions.rb'
require 'builders.rb'

#
# Initialized the Simulation with objects that the human can manipulate.
#
# The class name should be unique and so that the Players can not instantiate this class
#
#
class TheMatrix

  def self.sandbox= s
    @@matrix = s
  end

  # Reference all interesting class that we want to have available inside
  # the game world
  def initialize
    # References are protected because
    # the methods are marshalled in-out of the Matrix

    @@matrix.ref ActiveRecord
    @@matrix.ref ActiveRecord::Associations
    @@matrix.ref ActiveRecord::Associations::BelongsToAssociation
    @@matrix.ref ActiveRecord::Associations::HasOneAssociation
    @@matrix.ref ActiveRecord::Associations::HasManyAssociation
    @@matrix.ref ActiveRecord::Reflection
    @@matrix.ref ActiveRecord::Reflection::AssociationReflection
    @@matrix.ref ActiveSupport::Dependencies
    @@matrix.ref ActiveRecord::Errors
    @@matrix.ref ActiveRecord::ConnectionAdapters
    @@matrix.ref ActiveRecord::ConnectionAdapters::ConnectionPool

    @@matrix.ref Simcharacter

    # necessary to reference since we need to change the state of the player
    # note that we obfuscate by calling the class 'Simplayer'
    @@matrix.ref Simplayer

    @@matrix.ref Simperson
    @@matrix.ref Simplace
    @@matrix.ref Simthing

    # Builders
    # CharacterBuilder.proxy = Simcharacter.new
    # @@matrix.ref CharacterBuilder

    PlaceBuilder.proxy = Simplace.new
    @@matrix.ref PlaceBuilder

    # PlayerBuilder.proxy = Simplayer.new
    # @@matrix.ref PlayerBuilder
    #
    # PersonBuilder.proxy = Simperson.new
    # @@matrix.ref PersonBuilder

    Thinger.proxy = Simthing.new
    @@matrix.ref Thinger



    @@matrix.ref Simdoor
    @@matrix.ref Simkey
    @@matrix.ref Simnorth
    @@matrix.ref Simsouth
    @@matrix.ref Simeast
    @@matrix.ref Simwest
    @@matrix.ref Simup
    @@matrix.ref Simdown
    @@matrix.ref Simmap
    #    @@matrix.ref Connections


    # Simulation extensions
    # These classes are available within the Simulation.
    # Players may instanitate these classes.
    HardLine::sandbox = @@matrix
    @@matrix.ref HardLine
    #HackerIRB.add_frozen 'HardLine='
    #HackerIRB.add_frozen 'HardLine ='

    SocketServer::sandbox = @@matrix
    @@matrix.ref SocketServer

    SocketClient::sandbox = @@matrix
    @@matrix.ref SocketClient

    @@matrix.import SocketServerHandler
    @@matrix.import SocketClientHandler

  end

end


#
# This class is used to change the Source Code of the Simulation. Normally this is used by the Architect.
#
# The class name should be unique and so that the Players can not instantiate this class.
#
# This class is referenced within the Simulation, so it is instantiable within the Simulation.
#
#  thesource = TheSource.new     # instantiate within the Simulation
#  thesource.evaluate "class Apple; end"  # creates the Apple class, outside the Simulation, from the inside!
#  thesource.evaluate "apple = Apple.new" # instantiates the Apple class, outside the Simulation, from the inside!
#
class TheSource

  # Hides the Simulation from direct manipulation
  def self.sandbox= s
    @@sandbox = s
  end

  def initialize
    puts "Detected TheSource being instantiated."
  end

  # Make available the Simulation
  def self.magicbox
    @@sandbox
  end

  # *WARNING*
  # Changes the source code of the Simulation Server from _inside_ the Simulation
  #
  # Evaluate the source change into the TOP LEVEL BINDING of the Simulation Server
  def self.evaluate change
    Kernel::eval('#{change}', TOPLEVEL_BINDING)
  end

  # *WARNING*
  # Loads a file (usually containing a class definition) and creates a reference to the klass
  # Once the reference is made, that klass becomes instantiable within the Simulation
  def self.load(filename, klassname)
    puts filename
    p filename
    Kernel::eval("load #{filename}", TOPLEVEL_BINDING)
    Kernel::eval("TheSource.magicbox.ref #{klassname}", TOPLEVEL_BINDING)
  end

end



# This class is used to change the Source Code of the Simulation. Normally this is used by the Architect.
# The class name should be unique and so that the Players can not instantiate this class.
class TheSystem

  # Hide the simulation
  def self.sandbox= s
    @@sandbox = s
  end

  def initialize
  end

  def self.magicbox
    @@sandbox
  end

  # Create a proxy for an external class. The proxy marshals parameters and also marshals the return value.
  # This allows an Agent to request an action that takes place outside the Simulation, from the inside.
  #
  def self.agent_request klassname
    #Kernel::eval("class #{klassname} ; end ", TOPLEVEL_BINDING)
    begin
      Kernel::eval("TheSystem.magicbox.ref #{klassname}", TOPLEVEL_BINDING)
    rescue
      puts "Agent requesting a klass that does not exist."
    end
  end

  # Copy class into the Simulation, with its own definition
  def self.neo_request klassname
    begin
      Kernel::eval("TheSystem.magicbox.import #{klassname}", TOPLEVEL_BINDING)
    rescue
      puts "Neo requesting a klass that does not exist."
    end
  end

end






