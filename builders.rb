# Contains classes that assist with building Game World Objects

class GameObjectManager
  
  # Set inside the Simulation
  def initialize io
    @interface = io
  end
  
  # Set outside the Simulation by the Server. Hides the ORM object within the Simulation
  def self.proxy= theproxy
   @@orm = theproxy
  end
end

# Thinger is a proxy, used to protect the Database Table from direct manipulation
#
#
#   thingmaker = Thinger.new IOobject
#   thingmaker.make 'blue apple', 'this is a blue apple', HardLine.(IOobject).new.request('http://mysite.com/script.rb')
#  
class Thinger < GameObjectManager
  
  # Set inside the Simulation
  def initialize io
    super(io)
  end
  
  attr_writer :name, :description, :script, :strength, :weight, :portable, :visible, :container, :platform, :clothing
  
  # Creates a Thing and drops it inside the current room
  def make(name, description, script = "")      
    @thing = @@orm.make_thing(@interface, name, description, script)
    @interface.puts "Created #{@thing.name} with id of #{@thing.uniquid}."
    
    name = '#{@name}'
    #{@matrix_character} = Simcharacter.find(:first, :conditions => ['name = ?', name], :include => [{:simperson => :simplace}])
    
    character = Simcharacter.find(:first, :conditions => ['name = ?', @interface.character_name], :include => [{:simperson => :simplace}])
    character.simperson.simplace.simthings << @thing
    character.simperson.simplace.save!
    @interface.puts "#{@thing.name} appears on the floor."
  end
  
  # Returns an array of uniqueids
  def uniqueids name    
    @things = @@orm.class.find(:all, :select => ['things.uniqueid'], :conditions => ['name = ?', name])
    return nil if !@things
    result = []
    @things.each do |t|
      result << t.uniqueid
    end
    result
  end
  
  # Returns a Thing by uniquid
  def locate uniqid
    @thing = @@orm.class.find(:all, :conditions => ['uniqid = ?', uniquid])
    
    return nil if !@thing
    @name = @thing.name
    @description = @thing.description
    @script = @thing.script
    @strength = @thing.strength
    @weight = @thing.weight
    @portable = @thing.portable
    @visible = @thing.visible
    @container = @thing.container
    @platform = @thing.platform
    @clothing = @thing.clothing
  end
  
  # Saves this Thing into the Database
  def save
    return if !@thing
    @thing.name = @name
    @thing.description = @description
    @thing.script = @script
    @thing.strength = @strength
    @thing.weight = @weight
    @thing.portable = @portable
    @thing.visible = @visible
    @thing.container = @container
    @thing.platform = @platform
    @thing.clothing = @clothing
    @thing.save!
  end
  
end


# PlaceBuilder is used to create and modify Places within the Game World
#
#
#   placebuilder = PlaceBuilder.new IOobject
#   placebuilder.build_east 'Asia', 'Never get into a land war in south east asia', HardLine.(IOobject).new.request('http://mysite.com/script.rb')
#
#
class PlaceBuilder < GameObjectManager

  
  # Builds or modifies a Room to the East
  def build_east(name, description, script = "")    
    @character = Simcharacter.find(:first, :select => 'simcharacters.name, personsimpeople.character_id', :conditions => ['name = ?', @interface.character_name], :include =>[:simperson])
    if @character.simperson.simplace.east_to == nil then
      @character.simperson.simplace.build_east_place(name, description, @interface.character_name, script.to_str)
    else
      @character.simperson.simplace.east_to.name = name
      @character.simperson.simplace.east_to.description = description
      @character.simperson.simplace.east_to.creatorname = @interface.character_name
      @character.simperson.simplace.east_to.script = script.to_str
      @character.simperson.simplace.east_to.save!
    end
    "Done."
  end
  
  # Builds or modifies a Room to the West
  def build_west(name, description, script = "")      
    @character = Simcharacter.find(:first, :select => 'simcharacters.name, personsimpeople.character_id', :conditions => ['name = ?', @interface.character_name], :include =>[:simperson])
    if @character.simperson.simplace.west_to == nil then
    @character.simperson.simplace.build_west_place(name, description, @interface.character_name, script.to_str)
    else
      @character.simperson.simplace.west_to.name = name
      @character.simperson.simplace.west_to.description = description
      @character.simperson.simplace.west_to.creatorname = @interface.character_name
      @character.simperson.simplace.west_to.script = script.to_str
      @character.simperson.simplace.west_to.save!
    end
    "Done."
  end
  
  # Builds or modifies a Room to the North
  def build_north(name, description, script = "")      
    @character = Simcharacter.find(:first, :select => 'simcharacters.name, personsimpeople.character_id', :conditions => ['name = ?', @interface.character_name], :include =>[:simperson])
    if @character.simperson.simplace.north_to == nil then
    @character.simperson.simplace.build_north_place(name, description, @interface.character_name, script.to_str)
    else
      @character.simperson.simplace.north_to.name = name
      @character.simperson.simplace.north_to.description = description
      @character.simperson.simplace.north_to.creatorname = @interface.character_name
      @character.simperson.simplace.north_to.script = script.to_str
      @character.simperson.simplace.north_to.save!
    end
    "Done."
  end
  
  # Builds or modifies a Room to the South
  def build_south(name, description, script = "")      
    @character = Simcharacter.find(:first, :select => 'simcharacters.name, personsimpeople.character_id', :conditions => ['name = ?', @interface.character_name], :include =>[:simperson])
    if @character.simperson.simplace.south_to == nil then
    @character.simperson.simplace.build_south_place(name, description, @interface.character_name, script.to_str)
    else
      @character.simperson.simplace.south_to.name = name
      @character.simperson.simplace.south_to.description = description
      @character.simperson.simplace.south_to.creatorname = @interface.character_name
      @character.simperson.simplace.south_to.script = script.to_str
      @character.simperson.simplace.south_to.save!
    end
    "Done."
  end
  
  # Builds or modifies a Room above
  def build_up(name, description, script = "")      
    @character = Simcharacter.find(:first, :select => 'simcharacters.name, personsimpeople.character_id', :conditions => ['name = ?', @interface.character_name], :include =>[:simperson])
    if @character.simperson.simplace.up_to == nil then
    @character.simperson.simplace.build_up_place(name, description, @interface.character_name, script.to_str)
    else
      @character.simperson.simplace.up_to.name = name
      @character.simperson.simplace.up_to.description = description
      @character.simperson.simplace.up_to.creatorname = @interface.character_name
      @character.simperson.simplace.up_to.script = script.to_str
      @character.simperson.simplace.up_to.save!
    end
    "Done."
  end
  
  # Builds or modifies a Room below
  def build_down(name, description, script = "")      
    @character = Simcharacter.find(:first, :select => 'simcharacters.name, personsimpeople.character_id', :conditions => ['name = ?', @interface.character_name], :include =>[:simperson])
    if @character.simperson.simplace.down_to == nil then
    @character.simperson.simplace.build_down_place(name, description, @interface.character_name, script.to_str)
    else
      @character.simperson.simplace.down_to.name = name
      @character.simperson.simplace.down_to.description = description
      @character.simperson.simplace.down_to.creatorname = @interface.character_name
      @character.simperson.simplace.down_to.script = script.to_str
      @character.simperson.simplace.down_to.save!
    end
    "Done."
  end


end









