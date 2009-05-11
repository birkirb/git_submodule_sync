require 'yaml'

class GITRepoManager
  attr_reader :config, :repos, :repos_acting_as_submodules, :repos_using_submodules

  REPOSITORIES = 'data/repos'

  def initialize(config = 'config/repos.yml')
    @config = config
    @repos = symbolize_keys(YAML.load_file(config))
    split_repos
    FileUtils.mkdir_p(REPOSITORIES)
  end

  def clone_repos_using_submodules
    @repos_using_submodules.each do |k, v|
      clone_repo(k, @repos[k][:url]) unless repo_cloned?(k)
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
    File.exists?(File.join(REPOSITORIES, name.to_s, '.git'))
  end

  def clone_repo(name, url)
    if name.nil? || url.nil?
      raise 'Missing Repository Name or URL'
    else
      `git clone #{url} #{File.join(REPOSITORIES, name.to_s)}`
    end
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
