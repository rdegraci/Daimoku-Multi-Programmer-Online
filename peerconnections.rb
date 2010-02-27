#
# Manages all CharacterProxy objects so that messages can be sent to all or some sockets
#
# CharacterProxy objects are stored in a hash, using the SessionID as the key
#
# The Architect is not part of the peer connections, therefore the Architect does not get
# socket communications from the Players.
#
class PeerConnections

  @@proxies = {}

  # Used to report System Events
  def self.system_emote (text)
    puts "sytem_emote #{text}"
    @@proxies.each_pair do |k,v|
      raise if v.socket.closed? == true
      v.socket.puts "\n#The System: #{text}" if (CharacterProxy::is_hack_mode(k) == true)
    end
  end


  # Removes the CharacterProxy that is represented by the characterproxy's sessionid
  def remove characterproxy
    return if characterproxy.name == "Architect"
    @@proxies[characterproxy.session_id] = nil
    @@proxies.delete characterproxy.session_id
  end



  # Called by TheReaper, as part of Player death
  def disconnect sessionid
    puts "System reaping sessionid: #{sessionid}"
    characterproxy = @@proxies[sessionid]
    return if !characterproxy
    characterproxy.socket.puts "\n Your body can not live without your mind." if characterproxy.socket && characterproxy.socket.closed? == false
    characterproxy.system_logout
  end

  def system_say(sessionid, message)
    characterproxy = @@proxies[sessionid]
    return if !characterproxy
    puts "System saying: #{message} to  #{sessionid}"
    characterproxy.socket.puts "\n #{message}"
  end

  # Adds the CharacterProxy that is represented by the characterproxy's sessionid
  def add characterproxy
    return if characterproxy.name == "architect"
    @@proxies[characterproxy.session_id] = characterproxy
  end

  # Say a message to everyone in the PeerConnections
  def say_global(text, characterproxy)
    puts "say_global #{text}"
    raise if !characterproxy
    @@proxies.each_pair do |k,v|
      raise if v.socket.closed? == true
      v.socket.puts "\n#{characterproxy.name} shouts, #{text} !" if characterproxy.session_id != k
    end
    nil
  end


  # Say a message to someone privately
  def say_private(session_id, text)
    raise if !session_id
    @@proxies[session_id].socket.puts(text) if @@proxies[session_id]
    puts "say_private #{text} to #{@@proxies[session_id].name}" if @@proxies[session_id]
  end

  # Global Emote to everyone in the PeerConnections
  def emote_global(text, characterproxy)
    puts "emote_global #{text}"
    raise if !characterproxy
    @@proxies.each_pair do |k,v|
      raise if v.socket.closed? == true
      v.socket.puts "\n#{text}" if characterproxy.session_id != k
    end
    nil
  end

  # Say a line of code to everyone in the PeerConnections
  def say_global_code(text, characterproxy)
    puts "say_global_code #{text}"
    raise if !characterproxy
    @@proxies.each_pair do |k,v|
      raise if v.socket.closed? == true
      v.socket.puts "\n#{characterproxy.name}: #{text}" if ((characterproxy.session_id != k) && (v.mode == :wiretapon ))
    end
    nil
  end

end
