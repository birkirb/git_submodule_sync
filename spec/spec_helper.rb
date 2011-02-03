TEMP_DIRECTORY = '/tmp/spec_testing'

def initalize_repos
  remove_temp_directory

  FileUtils.mkdir_p(TEMP_DIRECTORY)

  @test_dir = File.join(File.dirname(__FILE__), 'files')
  @test_git_sub_bare = File.join(@test_dir, 'git', 'submodule.git')
  @test_git_usesub_bare = File.join(@test_dir, 'git', 'using_submodule.git')

  @git_sub_bare = copy_bare_repo(@test_git_sub_bare)
  @git_usesub_bare = copy_bare_repo(@test_git_usesub_bare)

  # Instantiante Git repo objects for testing
  @git_repo_sub = clone_repo(@git_sub_bare, non_bare_name_from_path(@git_sub_bare), TEMP_DIRECTORY)
  @git_repo_using_sub = clone_repo(@git_usesub_bare, non_bare_name_from_path(@git_usesub_bare), TEMP_DIRECTORY)

  @sub_path = File.join(TEMP_DIRECTORY, non_bare_name_from_path(@git_sub_bare))
  @usesub_path = File.join(TEMP_DIRECTORY, non_bare_name_from_path(@git_usesub_bare))

  # Add the submodule
  @git_repo_using_sub.add_submodule(@git_sub_bare, :path => 'plugins/some_module')
  @git_repo_using_sub.add('.')
  @git_repo_using_sub.commit('Adding submodule')
  @git_repo_using_sub.push
  $logger.info("---------- TEST REPOS INITIALIZED ---------")
end

def copy_bare_repo(bare_repository_path)
  tmp_path = File.join(TEMP_DIRECTORY, bare_repository_path.split('/').last)
  FileUtils.cp_r(bare_repository_path, File.join(tmp_path))
  tmp_path
end

def non_bare_name_from_path(bare_path)
  bare_path.split('/').last.split('.')[0]
end

def clone_repo(source, name, destination)
  Git.clone(source, name, :path => destination, :log => $logger)
end

def remove_temp_directory
  FileUtils.rm_r(TEMP_DIRECTORY) if File.exists?(TEMP_DIRECTORY)
end

def update_submodule
  `echo "Updating submodule with additional line in readme." >> #{@sub_path}/README`
  @git_repo_sub.add('.')
  @git_repo_sub.commit('New line in readme')
  @git_repo_sub.push('origin')
  @git_repo_sub.log.first
end
