require 'rubygems'
require 'sinatra'

root_dir = File.dirname(__FILE__)

set :environment, (ENV['RACK_ENV'] || 'production').to_sym
set :root,        root_dir
disable :run

require File.join(root_dir, 'commit_monitor.rb')
run Sinatra::Application
