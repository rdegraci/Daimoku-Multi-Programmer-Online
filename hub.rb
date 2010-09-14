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

  # Reset the warnings
  def clear_warning
    @mutex.lock
    @warning = ""
    @simulation_client = ""
    @eval_result = ""
    @mutex.unlock
  end
  
  # Change the Matrix, callable by outside scripts
  # or the Rails Application
  def dejavu code
    script = %{
      #{code}
    }
    @matrix.eval script
  end

  # Warning messages are sent by the System, to the Agents when an anomaly is detected.
  # Agents may also send warnings to each other
  def warning(message, simulation_client, eval_result = "")
    @mutex.lock
    @warning = message
    @simulation_client = simulation_client
    @eval_result = eval_result
    @mutex.unlock
  end

  # Information messages are sent by the System to the Agents to inform them of System status
  # Agents may also send warnings to each other
  def information(message, simulation_client, eval_result = "")
    @mutex.lock
    @info = message
    @simulation_client = simulation_client
    @eval_result = eval_result
    @mutex.unlock
  end

  # Fatalpriority messages are sent by the System to the Agents to inform them of a Fatal event
  # Agents may also send warnings to each other
  def fatalpriority(message)
    @mutex.lock
    @fatal = message
    @mutex.unlock
  end

  def simulation= sandbox
    @mutex.lock
    @matrix = sandbox
    @mutex.unlock
  end
  
  def simulation_client
    @mutex.lock
    copy = @simulation_client.clone
    @mutex.unlock
    copy
  end

  def eval_result
    @mutex.lock
    copy = @eval_result.clone
    @mutex.unlock
    copy
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

