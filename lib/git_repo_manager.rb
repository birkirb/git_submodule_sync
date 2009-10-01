require 'rubygems'
require 'yaml'
require 'lib/global_logger'
require 'git'
require 'fileutils'

class GITRepoManager
  attr_reader :config_file, :clone_path, :submodules, :config_hash

  def initialize(config = 'config/repos.yml', clone_path = 'data/repos')
    @config_file = config
    $logger.info("Config: #{@config_file}")
    raise 'Missing config file!' unless File.exists?(config)
    @config_hash = GITRepoManager.symbolize_keys(YAML.load_file(config))
    process_config_hash
    FileUtils.mkdir_p(clone_path)
    @clone_path = clone_path
      @cloned_repos = []
    @repos = {}
  end

  # Submodule's branch has been update to commit.
  # All repositories containing submodule should be update to that commit
  def update_submodule(uri, branch, commit)
    updated = []
    clone_or_pull_repositories

    $logger.info("Received commit #{commit[0..8]} from #{uri}, branch #{branch}")

    @repos_using_submodules.each do |repo_name|
      $logger.debug("Checking '#{repo_name}' for submodules")

      repo = @repos[repo_name]

      repo.submodules.each do |submodule|
        submodule_path = submodule.path
        submodule_uri = submodule.uri
        $logger.debug("Repo '#{repo_name}' has submodule '#{submodule_path}', #{submodule_uri}")

        normalized_local = GITRepoManager.normalize_git_uri(submodule_uri)
        normalized_receiving = GITRepoManager.normalize_git_uri(uri)

        $logger.debug("Comparing: #{normalized_local} == #{normalized_receiving}")
        if normalized_local == normalized_receiving
          $logger.debug("Found submodule #{uri} as #{submodule_path} in #{repo_name}")
          # repo has a submodule corresponding to uri

          submodule.init unless submodule.initialized?
          submodule.update unless submodule.updated?

          if repo.is_branch?(branch)
            $logger.info("Updating `#{repo_name}` with submodule branch `#{branch}`.")
            repo.branch(branch).checkout
            repo.reset_hard("origin/#{branch}")

            # repo has a branch with the same name as the submodule
            sub_repo = submodule.repository
            sub_repo.remote.fetch
            sub_repo.checkout(commit)

            repo.add(submodule_path)
            message = "Auto-updating submodule #{submodule} to commit #{commit}."
            repo.commit(message)
            repo.push('origin', branch)
            updated << message
            $logger.debug("Commit message: #{message}")
          else
            $logger.info("Repository #{repo_name} does not have a branch called #{branch}")
          end
        end
      end
    end
    updated
  end

  private

  def clone_or_pull_repositories
    debug_logger = $DEBUG ? $logger : nil
    @repos_using_submodules.each do |name|
      uri = @config_hash[name][:uri]

      if repo_cloned?(name)
        repo = Git.open(repo_path(name), :log => debug_logger)
        $logger.debug("Pulling from repository at #{uri}")
        repo.fetch
      else
        $logger.info("Cloning repository at #{uri}")
        repo = Git.clone(uri, name.to_s, :path => @clone_path, :log => debug_logger)
      end
      @repos[name] = repo
    end
  end


  def process_config_hash
    @submodules = []
    @repos_using_submodules = []
    listed_submodules = []

    @config_hash.each do |key, value|
      if submoduled_in = value[:submoduled_in]
        listed_submodules.concat(submoduled_in)
        @submodules.push(key)
      else
        @repos_using_submodules.push(key)
      end
    end

    @submodules.uniq!
    @repos_using_submodules.uniq!
  end

  def repo_cloned?(name)
    File.exists?(File.join(repo_path(name), '.git'))
  end

  def repo_path(name)
    File.join(@clone_path, name.to_s)
  end

  def self.symbolize_keys(hash)
    new_hash = Hash.new
    hash.each do |key, value|
      key = key.to_sym
      if value.is_a?(Hash)
        new_hash[key] = symbolize_keys(value)
      else
        new_hash[key] = value
      end
    end
    new_hash
  end

  def self.normalize_git_uri(uri)
    normalized_uri  = uri.dup

    if uri.match(/^\/(.*)$/)
      # Is local, remove leading
      normalized_uri = $1
    end

    if uri.match(/^file:\/\/\/(.*)$/)
      # Is local cut off file protocol
      normalized_uri = $1
    end

    if uri.match(/^https?:\/\/github.com\/(.*)$/)
      # Cut off github prefix
      normalized_uri = $1
    end

    if uri.match(/^git@github.com:(.*)$/)
      # Cut off github prefix
      normalized_uri = $1
    end

    if uri_without_git = normalized_uri.match(/(.*?)\/?\.git\/?$/)
      normalized_uri = uri_without_git[1]
    end

    normalized_uri
  end

end
