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
  def update_submodule(submodule_name, branch, commit)
    $logger.info("Received commit #{commit[0..8]} for submodule #{submodule_name}, branch #{branch}")

    @repos_using_submodules.each do |repo_name|
      $logger.debug("Checking #{repo_name} for submodules")

      repo = @repos[repo_name]

      repo.submodules.each do |submodule|
        $logger.debug("Repo #{repo_name} has submodule #{submodule.path}")

        if submodule.path.index(submodule_name)
          $logger.debug("Found submodule #{submodule_name} as #{submodule.path} in #{repo_name}")
          # repo has a submodule corresponding to submodule_name

          submodule.init unless submodule.initialized?
          submodule.update unless submodule.updated?

          if repo.is_branch?(branch)
            $logger.debug("Repo has identical branch as submodule #{branch}")

            # repo has a branch with the same name as the submodule
            sub_repo = submodule.repository
            sub_repo.remote.fetch
            sub_repo.checkout(commit)

            repo.add(submodule.path)
            repo.commit("Auto-updating submodule #{submodule} in branch #{branch} to commit #{commit}.")
            repo.push('origin', branch)
          else
            raise "Repository #{repo_name} does not have a branch called #{branch}"
          end
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

  def clone_repo(name, uri)
    if name.nil? || uri.nil?
      raise 'Missing Repository Name or URI'
    else
      if repo_cloned?(name)
        repo = Git.open(repo_path(name), :log => $logger)
      else
        repo = Git.clone(uri, name.to_s, :path => @clone_path, :log => $logger)
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
