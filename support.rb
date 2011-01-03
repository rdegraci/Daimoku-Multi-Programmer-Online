# Support classes are used by the SimulationServer to create the overall System. These classes may be available to Agents or Neo
require 'rubygems'
require 'active_record'

# When using ActiveRecord::Associations outside of Rails, a NameError is thrown
# irb(main):002:0> require 'rubygems' => true 
# irb(main):003:0> require 'active_record' => true 
# irb(main):004:0> ActiveRecord => ActiveRecord 
# irb(main):005:0> ActiveRecord::Associations NameError: uninitialized constant ActiveRecord::Associations
# Rhett Sutphin
# April 3rd, 2010 @ 02:28 AM
# Seems to me that the lowest-impact fix would be to move ActiveRecordError out of base.rb and into its own file. 
# That would break the autoload cycle (ActiveRecordError loads from base.rb, base.rb loads Associations, Associations loads ActiveRecordError).
# In any case, another workaround is to explicitly require 'active_record/base' after requiring 'active_record'.
require 'active_record/base'

require 'active_support'
require 'active_resource'


# Necessary to require mysql_api here, to prevent
# undefined method `require' for main:Object error
require 'mysql_api'

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

require '/usr/local/daimoku-rails/app/models/sim_module.rb'
require '/usr/local/daimoku-rails/app/models/sim_klass.rb'
require '/usr/local/daimoku-rails/app/models/sim_variable.rb'
require '/usr/local/daimoku-rails/app/models/sim_script.rb'

require '/usr/local/daimoku-server/matrix-extensions.rb'
require '/usr/local/daimoku-server/builders.rb'

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
    @@matrix.ref ActiveSupport::OrderedHash
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
    
    @@matrix.import Edible
    
    @@matrix.ref SimModule
    SimModule.sandbox = @@matrix
    
    @@matrix.ref SimKlass
    SimKlass.sandbox = @@matrix    
    
    @@matrix.ref SimVariable
    SimVariable.sandbox = @@matrix
    
    @@matrix.ref SimScript
    SimScript.sandbox = @@matrix
    SimScript.load_script 'startup' #build the in-world modules, classes, variables

  end

end


#
# This class is used to change the Source Code of the Simulation. Normally this is used by the Architect.
#
# The class name should be unique and so that the Players can not instantiate this class.
#
# This class is referenced within the Simulation, so it is instantiable within the Simulation.
#
#  TheSource.evaluate "class Apple; end"  # creates the Apple class, outside the Simulation, from the inside!
#  TheSource.evaluate "apple = Apple.new" # instantiates the Apple class, outside the Simulation, from the inside!
#
class TheSource

  # Hides the Simulation from direct manipulation
  def self.sandbox= s
    @@sandbox = s
  end

  def initialize
    puts "Detected TheSource being instantiated."
  end

  # *WARNING*
  # Changes the source code of the Simulation Server from _inside_ the Simulation
  #
  # Evaluate the source change into the TOP LEVEL BINDING of the Simulation Server
  def self.evaluate change
    change.gsub!(/`/,";")
    change.gsub!(/ +Kernel/,";") 
    change.gsub!(/ +Class/,";") 
    change.gsub!(/ +Object/,";")
    change.gsub!(/ +Module/,";")
    change.gsub!(/ +File/,";")
    change.gsub!(/ +IO/,";")
    change.gsub!(/ +Thread/,";")
      
    code = %{
      #{change}
    }
    puts "TheSource is evaluating:#{code}"
    begin
      Kernel::eval(code, TOPLEVEL_BINDING)
    rescue
      puts "Unable to evaluate: #{code}"
    end
  end
  
  # *WARNING*
  # Adds or changes the Simulation from _inside_ the Simulation
  #
  def self.dejavu change
    code = %{
      #{change}
    }
    puts "TheSource.dejavu #{code}"
    begin
      Kernel::eval("@@sandbox.eval(#{code})")
    rescue
      puts "Unable to evaluate: #{code}"
    end
  end

  # *WARNING*
  # Loads a file (usually containing a class definition) and creates a reference to the klass
  # Once the reference is made, that klass becomes instantiable within the Simulation
  def self.load(filename, klassname)
    begin
      Kernel::eval("load #{filename}", TOPLEVEL_BINDING)
      Kernel::eval("@@sandbox.ref(#{klassname})")
    rescue
      puts "Unable to load #{filename} and reference #{klassname}"
    end
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


  # Create a proxy for an external class. The proxy marshals parameters and also marshals the return value.
  # This allows an Agent to request an action that takes place outside the Simulation, from the inside.
  #
  # The class must already exist outside the Simulation:
  #
  #
  # 
  def self.agent_request klassname
    begin
      Kernel::eval("@@sandbox.ref(#{klassname})")
    rescue
      puts "Agent requesting a klass that does not exist."
    end
  end

  # Copy class into the Simulation, with its own definition
  # The class must first exist in the Simulation:
  #
  #   class Apple
  #   def eat
  #    "yum"
  #   end
  #   end
  #   TheSystem.request 'Apple'
  #   apple = Apple.new
  #   apple.eat
  #
  def self.neo_request klassname
    begin
      #Kernel::eval("TheSystem.magicbox.import #{klassname}", TOPLEVEL_BINDING)
      Kernel::eval("@@sandbox.import(#{klassname})")
    rescue
      puts "Neo requesting a klass that does not exist."
    end
  end
  
  # Copy class into the Simulation, with its own definition
  # The class must first exist in the Simulation:
  #
  #   class Apple
  #   def eat
  #     "yum"
  #   end
  #   end
  #   TheSystem.request 'Apple'
  #   apple = Apple.new
  #   apple.eat
  #
  def self.request klassname
    begin
      #Kernel::eval("TheSystem.magicbox.import #{klassname}", TOPLEVEL_BINDING)
      Kernel::eval("@@sandbox.import(#{klassname})")
    rescue
      puts "System requesting a klass that does not exist."
    end
  end

end






