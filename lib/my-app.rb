#!/usr/bin/env ruby

##
# Setup and run the application

require 'rubygems'
require 'gtk2'
require 'log4r'
require 'ruby-prof'
require 'launchy'
require 'singleton'

require 'lib/extensions'
require 'lib/controllers/database'

# let the filename be the application name
# ex: Fred.rb: APP => 'Fred'
APP = File.basename(__FILE__, '.*')

# configure Logger
Log4r::Logger.new(APP)
Log4r::Logger[APP].outputters = Log4r::StdoutOutputter.new(:console)
Log4r::Outputter[:console].formatter = Log4r::PatternFormatter.new(:pattern => "[%l %t] %M")
Log4r::Logger[APP].level = Log4r::INFO
Log4r::Logger[APP].trace = true

require 'lib/app' # note: setup logger before requiring the app

if __FILE__ == $0
  begin
    App.setup :name => "<%= @name %>",
              :description => "<%= @description %>",
              :version => "<%= @version %>",
              :authors => ["<%= @authors %>"],
              :license => "<%= @license %>",
              :images => ["Gtk_Ruby_128.png", "Gtk_Ruby_256.png"]
    App.execute
  rescue Exception => eMsg
    Log4r::Logger[APP].error eMsg
  end
end

