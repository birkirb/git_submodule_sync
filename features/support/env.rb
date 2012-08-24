require 'sinatra'
require 'rack/test'
require 'rspec/expectations'
require 'webrat'

$:.push(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
$:.push(File.join(File.dirname(__FILE__), '..', '..', 'spec'))

app_file = File.join(File.dirname(__FILE__), *%w[.. .. commit_monitor.rb])
Sinatra::Application.app_file = app_file
Sinatra::Application.set(:environment, :test)
require app_file

Webrat.configure do |config|
  config.mode = :rack
end

class SinatraWebRatApp
  include Rack::Test::Methods
  include Webrat::Methods
  include Webrat::Matchers
  include Webrat::HaveTagMatcher

  Webrat::Methods.delegate_to_session :response_code, :response_body

  def app
    Sinatra::Application
  end
end

World do
  SinatraWebRatApp.new
end
