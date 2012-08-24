TEMP_DIRECTORY = '/tmp/spec_testing'

def initalize_repos
  remove_temp_directory

  FileUtils.mkdir_p(TEMP_DIRECTORY)

  @test_dir = File.join(File.dirname(__FILE__), 'files')
  @test_git_sub_bare = File.join(@test_dir, 'git', 'submodule.git')
  @test_git_usesub_bare = File.join(@test_dir, 'git', 'using_submodule.git')

  @central_bare_repo_submodule = copy_bare_repo(@test_git_sub_bare)
  @central_bare_repo_using_submodule = copy_bare_repo(@test_git_usesub_bare)

  # Instantiante Git repo objects for testing
  @third_party_submodule_clone = clone_repo(@central_bare_repo_submodule)
  @third_party_using_submodule_clone = clone_repo(@central_bare_repo_using_submodule)

  @third_party_submodule_path = File.join(TEMP_DIRECTORY, non_bare_name_from_path(@central_bare_repo_submodule))
  @third_party_using_submodule_path = File.join(TEMP_DIRECTORY, non_bare_name_from_path(@central_bare_repo_using_submodule))

  # Add the submodule
  @third_party_using_submodule_clone.add_submodule(@central_bare_repo_submodule, :path => 'plugins/some_module')
  @third_party_using_submodule_clone.add('.')
  @third_party_using_submodule_clone.commit('Adding submodule')
  @third_party_using_submodule_clone.push
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

def clone_repo(source)
  Git.clone(source, non_bare_name_from_path(source), :path => TEMP_DIRECTORY, :log => $logger)
end

def remove_temp_directory
  FileUtils.rm_r(TEMP_DIRECTORY) if File.exists?(TEMP_DIRECTORY)
end

def change_submodule_via_third_party_checkout(branch = 'master', line = 'Updating submodule with additional line in readme.')
  @third_party_submodule_clone.branch(branch).checkout
  `echo "#{line}" >> #{@third_party_submodule_path}/README`
  @third_party_submodule_clone.add('.')
  @third_party_submodule_clone.commit('New line in readme', :author => 'Third party <thirdparty@localhost.local>')
  @third_party_submodule_clone.push('origin', branch)
  @third_party_submodule_clone.log.first
end

def change_using_submodule_via_third_party_checkout(branch = 'master', line = 'Line for the testing branch in the using_submodule repository.')
  @third_party_using_submodule_clone.branch(branch).checkout
  `echo "#{line}" >> #{@third_party_using_submodule_path}/README`
  @third_party_using_submodule_clone.add('.')
  @third_party_using_submodule_clone.commit('New line in using submodule readme.')
  @third_party_using_submodule_clone.push('origin', branch)
  @third_party_using_submodule_clone.log.first
end

def third_party_using_submodule_checkout
  @third_party_using_submodule_clone.fetch
  @third_party_using_submodule_clone.reset_hard("origin/master")
  @third_party_using_submodule_clone
end

def local_using_submodule_checkout
  git = Git.open(File.join(LOCAL_REPOS, 'using_submodule'), :log => $logger)
  git.fetch
  git.checkout('master')
  git.reset_hard('origin/master')
  git
end

def local_submodule_checkout
  Git.open(File.join(LOCAL_REPOS, 'submodule'), :log => $logger)
end
