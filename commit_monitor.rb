require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'json'
require 'fileutils'
require 'git_repo_manager'

repo_manager = nil

configure(:production) do
  repos = File.join(Dir.pwd, 'data', 'repos')
  config = File.join('config', 'repos.yml')
  repo_manager = GITRepoManager.new(config, repos)
end

configure(:test) do
  local_repos = File.join(Dir.pwd, 'spec', 'files', 'test_repos')
  test_config = File.join('spec', 'files', 'config', 'repos.yml')
  repo_manager = GITRepoManager.new(test_config, local_repos)
end

# Repositories are single-threaded
set :lock

repo_manager.submodules.each do |submodule_name|
  path = "/#{submodule_name}"

  get path do
    halt 403, 'Payload only accepted via POST'
  end

  post path do
    if params[:payload]
      payload = JSON.parse(params[:payload])
      $logger.info "Received payload from #{payload["repository"]["url"]}"
      payload["ref"].match(/\/([^\/]+)$/)
      message = repo_manager.update_submodule(payload["repository"]["url"], $1, payload["after"])
      message.to_s
    else
      halt 400, 'Payload missing'
    end
  end
end

# pingable url to make sure the app is running
get "/status" do
  "OK"
end
