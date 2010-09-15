# The system hub uses Distributed Ruby to send and receive notifications to/from the System and the Agents

require 'drb'
require 'hub.rb'
require 'yaml'


class SystemHubLoader

  def initialize matrix
    config = YAML.load_file('/usr/local/daimoku-server/drb.yaml')

    @systemhub = SystemHub.new
    @systemhub.simulation = matrix
    @drb = DRb.start_service("druby://#{config['server']}:#{config['port']}", @systemhub)
  end
end

