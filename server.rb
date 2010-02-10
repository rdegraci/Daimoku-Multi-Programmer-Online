#! /usr/local/bin/ruby

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'sandbox'

require 'rubygems'
require 'active_record'

require 'matrixserver.rb'
require 'matrixirb.rb'
require 'yaml'
require 'daemons'

puts   "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
puts
puts
puts    "Daimoku Multi Programmer Online  Copyright 2009 Rodney Degracia"
puts
puts
puts    "This program is free software: you can redistribute it and/or modify"
puts    "it under the terms of the GNU General Public License as published by"
puts    "the Free Software Foundation, either version 3 of the License, or"
puts    "(at your option) any later version."
puts
puts    "This program is distributed in the hope that it will be useful,"
puts    "but WITHOUT ANY WARRANTY; without even the implied warranty of"
puts    "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the"
puts    "GNU General Public License for more details."
puts
puts    "You should have received a copy of the GNU General Public License"
puts    "along with this program.  If not, see <http://www.gnu.org/licenses/>."
puts
puts
puts
puts    "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
puts
puts


config = YAML.load_file '/usr/local/daimoku-server/server.yaml'
SimulationServer.new(config['server'], config['port']).run.join


