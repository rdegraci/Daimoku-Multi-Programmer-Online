# SystemHub is the shared object used by the Distributed Ruby
# notification system of Daimoku Game World. The SystemHub is used
# to help relay messages from the System to the System Agents
class SystemHub

  # Initialize the messages
  def initialize
    @warning = ""
    @info = ""
    @fatal = ""
    @mutex = Mutex.new
  end

  # Warning messages are sent by the System, to the Agents when an anomaly is detected.
  # Agents may also send warnings to each other
  def warning message
    @mutex.lock
    @warning = message
    @mutex.unlock
  end

  # Information messages are sent by the System to the Agents to inform them of System status
  # Agents may also send warnings to each other
  def information message
    @mutex.lock
    @info = message
    @mutex.unlock
  end

  # Fatalpriority messages are sent by the System to the Agents to inform them of a Fatal event
  # Agents may also send warnings to each other
  def fatalpriority message
    @mutex.lock
    @fatal = message
    @mutex.unlock
  end

  # Warn status, read by the Agents
  def warn
    @mutex.lock
    copy = @warning.clone
    @mutex.unlock
    copy
  end

  # Info status, read by the Agents
  def info
    @mutex.lock
    info = @info.clone
    @mutex.unlock
    info
  end

  # Fatal status, read by the Agents
  def fatal
    @mutex.lock
    fatal = @fatal.clone
    @mutex.unlock
    fatal
  end

end
