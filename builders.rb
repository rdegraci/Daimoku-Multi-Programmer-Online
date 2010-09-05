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

  attr_accessor :name, :description, :script, :strength, :weight, :portable, :visible, :container, :platform, :clothing

  # Creates a Thing and drops it inside the current room
  def make(name, description, script = "")
    name.gsub!(/ /,"_")
    @thing = @@orm.make_thing(@interface, name, description, script)
    @interface.puts "Created #{@thing.name} with id of #{@thing.uniqueid}."

    name = '#{@name}'
    #{@matrix_character} = Simcharacter.find(:first, :conditions => ['name = ?', name], :include => [{:simperson => :simplace}])

    character = Simcharacter.find(:first, :conditions => ['name = ?', @interface.character_name], :include => [{:simperson => :simplace}])
    character.simperson.simplace.simthings << @thing
    character.simperson.simplace.save!

    @interface.puts "#{@thing.name} appears on the floor."
    
    klass = "\"class #{@thing.name.capitalize} ; end\""
    puts klass
    TheSource.dejavu(klass)
    TheSystem.request(@thing.name.capitalize)
    @interface.puts "Created class #{@thing.name.capitalize}. To use:  klass = #{@thing.name.capitalize}.new "
    sync
  end

  # Returns an array of uniqueids
  def uniqueids name
    @things = @@orm.class.find(:all, :select => ['simthings.uniqueid'], :conditions => ['name = ?', name])
    return nil if !@things
    result = []
    @things.each do |t|
      result << t.uniqueid
    end
    result
  end

  def sync
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
    self
  end

  # Returns a Thing by uniqueid
  def locate uniqueid
    @thing = @@orm.class.find(:all, :conditions => ['uniqueid = ?', uniqueid])

    return nil if !@thing
    sync
  end

  # Saves this Thing into the Database
  def save
    return false if !@thing
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
    true
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

  # Set inside the Simulation
  def initialize io
    super(io)
  end

  attr_writer :name, :description, :script, :enterscript, :exitscript

  # Returns an array of uniqueids
  def uniqueids name
    @places = @@orm.class.find(:all, :select => ['simplaces.uniqueid'], :conditions => ['name = ?', name])
    return nil if !@places
    result = []
    @places.each do |ppp|
      result << ppp.uniqueid
    end
    result
  end

  # Returns a Place by uniqueid
  def locate uniqid
    @place = @@orm.class.find(:all, :conditions => ['uniqeid = ?', uniqueid])

    return nil if !@place
    @name = @place.name
    @description = @place.description
    @script = @place.script
    @enterscript = @place.enterscript
    @exitscript = @place.exitscript
    self
  end

  # Saves this Thing into the Database
  def save
    return false if !@thing
    @place.name = @name
    @place.description = @description
    @place.script = @script
    @place.enterscript = @enterscript
    @place.exitscript  = @exitscript
    @thing.save!
    true
  end

  # Builds or modifies a Room to the East
  def build_east(name, description, script = ";")
    @character = Simcharacter.find(:first, :select => 'simcharacters.name, personsimpeople.character_id', :conditions => ['name = ?', @interface.character_name], :include =>[:simperson])
    if @character.simperson.simplace.east_to == nil then
      @character.simperson.simplace.build_east_place(name, description, @interface.character_name, script.to_str)
    else
      @character.simperson.simplace.east_to.name = name
      @character.simperson.simplace.east_to.description = description
      @character.simperson.simplace.east_to.creatorname = @interface.character_name
      @character.simperson.simplace.east_to.script = script.to_str
      @character.simperson.simplace.east_to.enterscript = ";"
      @character.simperson.simplace.east_to.exitscript = ";"
      @character.simperson.simplace.east_to.save!
    end
    "Done."
  end

  # Builds or modifies a Room to the West
  def build_west(name, description, script = ";")
    @character = Simcharacter.find(:first, :select => 'simcharacters.name, personsimpeople.character_id', :conditions => ['name = ?', @interface.character_name], :include =>[:simperson])
    if @character.simperson.simplace.west_to == nil then
      @character.simperson.simplace.build_west_place(name, description, @interface.character_name, script.to_str)
    else
      @character.simperson.simplace.west_to.name = name
      @character.simperson.simplace.west_to.description = description
      @character.simperson.simplace.west_to.creatorname = @interface.character_name
      @character.simperson.simplace.west_to.script = script.to_str
      @character.simperson.simplace.west_to.enterscript = ";"
      @character.simperson.simplace.west_to.exitscript = ";"
      @character.simperson.simplace.west_to.save!
    end
    "Done."
  end

  # Builds or modifies a Room to the North
  def build_north(name, description, script = ";")
    @character = Simcharacter.find(:first, :select => 'simcharacters.name, personsimpeople.character_id', :conditions => ['name = ?', @interface.character_name], :include =>[:simperson])
    if @character.simperson.simplace.north_to == nil then
      @character.simperson.simplace.build_north_place(name, description, @interface.character_name, script.to_str)
    else
      @character.simperson.simplace.north_to.name = name
      @character.simperson.simplace.north_to.description = description
      @character.simperson.simplace.north_to.creatorname = @interface.character_name
      @character.simperson.simplace.north_to.script = script.to_str
      @character.simperson.simplace.north_to.enterscript = ";"
      @character.simperson.simplace.north_to.exitscript = ";"
      @character.simperson.simplace.north_to.save!
    end
    "Done."
  end

  # Builds or modifies a Room to the South
  def build_south(name, description, script = ";")
    @character = Simcharacter.find(:first, :select => 'simcharacters.name, personsimpeople.character_id', :conditions => ['name = ?', @interface.character_name], :include =>[:simperson])
    if @character.simperson.simplace.south_to == nil then
      @character.simperson.simplace.build_south_place(name, description, @interface.character_name, script.to_str)
    else
      @character.simperson.simplace.south_to.name = name
      @character.simperson.simplace.south_to.description = description
      @character.simperson.simplace.south_to.creatorname = @interface.character_name
      @character.simperson.simplace.south_to.script = script.to_str
      @character.simperson.simplace.south_to.enterscript = ";"
      @character.simperson.simplace.south_to.exitscript = ";"
      @character.simperson.simplace.south_to.save!
    end
    "Done."
  end

  # Builds or modifies a Room above
  def build_up(name, description, script = ";")
    @character = Simcharacter.find(:first, :select => 'simcharacters.name, personsimpeople.character_id', :conditions => ['name = ?', @interface.character_name], :include =>[:simperson])
    if @character.simperson.simplace.up_to == nil then
      @character.simperson.simplace.build_up_place(name, description, @interface.character_name, script.to_str)
    else
      @character.simperson.simplace.up_to.name = name
      @character.simperson.simplace.up_to.description = description
      @character.simperson.simplace.up_to.creatorname = @interface.character_name
      @character.simperson.simplace.up_to.script = script.to_str
      @character.simperson.simplace.up_to.enterscript = ";"
      @character.simperson.simplace.up_to.exitscript = ";"
      @character.simperson.simplace.up_to.save!
    end
    "Done."
  end

  # Builds or modifies a Room below
  def build_down(name, description, script = ";")
    @character = Simcharacter.find(:first, :select => 'simcharacters.name, personsimpeople.character_id', :conditions => ['name = ?', @interface.character_name], :include =>[:simperson])
    if @character.simperson.simplace.down_to == nil then
      @character.simperson.simplace.build_down_place(name, description, @interface.character_name, script.to_str)
    else
      @character.simperson.simplace.down_to.name = name
      @character.simperson.simplace.down_to.description = description
      @character.simperson.simplace.down_to.creatorname = @interface.character_name
      @character.simperson.simplace.down_to.script = script.to_str
      @character.simperson.simplace.down_to.enterscript = ";"
      @character.simperson.simplace.down_to.exitscript = ";"
      @character.simperson.simplace.down_to.save!
    end
    "Done."
  end


end










