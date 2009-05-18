require 'rubygems'
require 'yaml'
require 'lib/global_logger'
require 'git'

class GITRepoManager
  attr_reader :config_file, :clone_path, :submodules, :config_hash

  def initialize(config = 'config/repos.yml', clone_path = 'data/repos')
    @config_file = config
    raise 'Missing config file!' unless File.exists?(config)
    @config_hash = symbolize_keys(YAML.load_file(config))
    process_config_hash
    FileUtils.mkdir_p(clone_path)
    @clone_path = clone_path
    @cloned_repos = []
    @repos = {}
  end

  def clone_repos_using_submodules
    @repos_using_submodules.each do |r|
      uri = @config_hash[r][:uri]
      $logger.info("Cloning repository at #{uri}")
      clone_repo(r, uri)
    end
  end

  # Submodule's branch has been update to commit.
  # All repositories containing submodule should be update to that commit
  def update_submodule(submodule, branch, commit)
    @repos_using_submodules.each do |name|
      repo = @repos[name]

      if repo.submodules.includes?(submodule)
        # repo has this submodule
        submodule = Git.submodule(submodule)
        submodule.init
        submodule.update

        if repo.branches.includes?(branch)
          # repo has a branch with the same name as the submodule
          sub_repo = submodule.repository
          sub_repo.remote.fetch
          sub_repo.checkout(commit)

          repo.add(submodule.path)
          repo.commit("Auto-updating submodule #{submodule} in branch #{branch} to commit #{commit}.")
          repo.push('origin', branch)
        end
      end
    end
  end

  private

  def process_config_hash
    @submodules = []
    @repos_using_submodules = []
    listed_submodules = []

    @config_hash.each do |k, v|
      if submoduled_in = v[:submoduled_in]
        listed_submodules.concat(submoduled_in)
        @submodules.push(k)
      else
        @repos_using_submodules.push(k)
      end
    end

    @submodules.uniq!
    @repos_using_submodules.uniq!
  end

  def repo_cloned?(name)
    File.exists?(File.join(repo_path(name), '.git'))
  end

  def repo_submodule_path(name)
    repo = @repos[name]
    i
    File.join(path, submodule_path)
  end

  def repo_has_submodule?(name, submodule)
  end

  def clone_repo(name, uri)
    if name.nil? || uri.nil?
      raise 'Missing Repository Name or URI'
    else
      if repo_cloned?(name)
        repo = Git.open(repo_path(name))
      else
        repo = Git.clone(uri, name.to_s, :path => @clone_path)
      end
      @repos[name] = repo
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
