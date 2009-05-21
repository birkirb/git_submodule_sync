require 'sinatra'
app_file = File.join(File.dirname(__FILE__), *%w[.. .. commit_monitor.rb])
Sinatra::Application.app_file = app_file
Sinatra::Application.set(:environment, :test)
require app_file

require 'spec/expectations'
require 'spec/matchers'
require 'webrat'

Webrat.configure do |config|
  config.mode = :sinatra
end
