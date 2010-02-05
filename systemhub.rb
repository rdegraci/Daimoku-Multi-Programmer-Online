# The system hub uses Distributed Ruby to send and receive notifications to/from the System and the Agents

require 'drb'
require 'hub.rb'
require 'yaml'

config = YAML.load_file 'drb.yaml'

DRb.start_service("druby://#{config['server']}:#{config['port']}", SystemHub.new)
DRb.thread.join
