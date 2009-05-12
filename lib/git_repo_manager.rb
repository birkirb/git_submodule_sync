require 'yaml'
require 'lib/global_logger'
require 'git'

class GITRepoManager
  attr_reader :repo_config, :clone_path, :repos

  def initialize(config = 'config/repos.yml', clone_path = 'data/repos')
    @repo_config = config
    raise 'Missing config file!' unless File.exists?(config)
    @repos = symbolize_keys(YAML.load_file(config))
    split_repos
    FileUtils.mkdir_p(clone_path)
    @clone_path = clone_path
    @cloned_repos = []
  end

  def clone_repos_using_submodules
    @repos_using_submodules.each do |k, v|
      url = @repos[k][:url]
      $logger.info("Cloning repository at #{url}")
      clone_repo(k, url) unless repo_cloned?(k)
    end
  end

  def update_submodule(submodule, branch)
    @repos[submodule.to_sym][:submoduled_in].each do |repo|
      if repo_cloned?(repo)
        submodule_path = repo_submodule_path(repo)
        puts submodule_path
      else
        raise "Unknown repository: #{repo}"
      end
    end
  end

  private

  def split_repos
    @repos_acting_as_submodules = []
    @repos_using_submodules = []
    listed_submodules = []

    @repos.each do |k, v|
      if submoduled_in = v[:submoduled_in]
        listed_submodules.concat(submoduled_in)
        @repos_acting_as_submodules.push(k)
      else
        @repos_using_submodules.push(k)
      end
    end

    @repos_acting_as_submodules.uniq!
    @repos_using_submodules.uniq!
  end

  def repo_cloned?(name)
    File.exists?(File.join(repo_path(name), '.git'))
  end

  def repo_submodule_path(name)
    path = repo_path(name)
    Git.open(path, :log => $logger)
    $logger.debug("Switching to repo in: #{path}")
    treeish, submodule_path, description = submodule_status.split(' ')
    $logger.debug("Found submodule #{submodule_path} on commit #{treeish}")
    File.join(path, submodule_path)
  end

  def clone_repo(name, url)
    if name.nil? || url.nil?
      raise 'Missing Repository Name or URL'
    else
      `git clone #{url} #{repo_path(name)}`
    end
  end

  def repo_path(name)
    File.join(@clone_path, name.to_s)
  end

  def symbolize_keys(hash)
    new_hash = Hash.new
    hash.each do |k,v|
      if v.is_a?(Hash)
        new_hash[k.to_sym] = symbolize_keys(v)
      else
        new_hash[k.to_sym] = v
      end
    end
    new_hash
  end

end
