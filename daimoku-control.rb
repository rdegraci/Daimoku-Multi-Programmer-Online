# Rodney Degracia
# February 2010 
# Daimoku daemon controller

#Usage:   ruby control.rb start|stop
require 'rubygems'
require 'daemons'

Daemons.run('server.rb')
