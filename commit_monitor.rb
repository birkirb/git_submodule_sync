require 'rubygems'
require 'sinatra'
require 'json'
require 'fileutils'
require 'lib/git_repo_manager'
require 'lib/global_logger'

repo_manager = nil

configure do
  repos = File.join(`pwd`.chomp, 'data/repos')
  config = 'config/repos.yml'
  repo_manager = GITRepoManager.new(config, repos)
end

configure :test do
  local_repos = File.join(`pwd`.chomp, 'spec/files/test_repos')
  test_config = 'spec/files/config/repos.yml'
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
      halt 403, 'Payload missing'
    end
  end
end
