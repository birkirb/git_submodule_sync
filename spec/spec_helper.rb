TEMP_DIRECTORY = '/tmp/spec_testing'

def initalize_repos
  remove_temp_directory

  @test_dir = File.join(File.dirname(__FILE__), 'files')
  @git_sub_bare = File.join(@test_dir, 'git', 'submodule.git')
  @git_usesub_bare = File.join(@test_dir, 'git', 'using_submodule.git')

  @sub_path = create_temp_repo(@git_sub_bare)
  @usesub_path = create_temp_repo(@git_usesub_bare)

  # Instantiante Git repo objects for testing
  @git_repo_using_sub = initalize_repo(@usesub_path)
  @git_repo_sub = initalize_repo(@sub_path)

  # Add the submodule
  @git_repo_using_sub.add_submodule(@sub_path, :path => 'plugins/some_module')
  @git_repo_using_sub.add('.')
  @git_repo_using_sub.commit('Adding submodule')
end

def create_temp_repo(clone_path)
  tmp_path = File.join(TEMP_DIRECTORY, clone_path.split('/').last.split('.')[0])
  FileUtils.mkdir_p(tmp_path)
  FileUtils.cp_r(clone_path, File.join(tmp_path, '.git'))
  tmp_path
end

def initalize_repo(repo_path)
  repo = Git.open(repo_path, :log => $logger)
  repo.reset_hard
  repo
end

def remove_temp_directory
  FileUtils.rm_r(TEMP_DIRECTORY) if File.exists?(TEMP_DIRECTORY)
end

def update_submodule
  `echo "Updating submodule with additional line in readme." >> #{@sub_path}/README`
  @git_repo_sub.add('.')
  @git_repo_sub.commit('New line in readme')
  @git_repo_sub.log.first
end
