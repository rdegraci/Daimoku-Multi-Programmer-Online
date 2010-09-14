# The system hub uses Distributed Ruby to send and receive notifications to/from the System and the Agents

require 'drb'
require 'hub.rb'
require 'yaml'


class SystemHubLoader

  def initialize matrix
    config = YAML.load_file('/usr/local/daimoku-server/drb.yaml')

    @drb = DRb.start_service("druby://#{config['server']}:#{config['port']}", SystemHub.new)
    @drb.simulation = matrix

  end
end

