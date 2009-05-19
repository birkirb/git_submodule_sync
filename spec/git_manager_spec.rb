require 'lib/git_repo_manager'
require 'lib/global_logger'
require 'spec/spec_helper.rb'
require 'git'

describe GITRepoManager do

  LOCAL_REPOS = File.join(`pwd`.chomp, 'spec/files/test_repos')
  TEST_CONFIG = 'spec/files/config/repos.yml'

  before(:all) do
    set_file_paths
    sub_path = create_temp_repo(@git_sub_bare)
    usesub_path = create_temp_repo(@git_usesub_bare)

    # Instantiante Git repo objects for testing
    @git_repo_using_sub = Git.open(usesub_path, :log => $logger)
    @git_repo_using_sub.reset_hard
    @git_repo_sub = Git.open(sub_path, :log => $logger)
    @git_repo_sub.reset_hard

    # Add the submodule
    @git_repo_using_sub.add_submodule(sub_path, :path => 'plugins/some_module')
    @git_repo_using_sub.add('.')
    @git_repo_using_sub.commit('Adding submodule')
  end

  after(:all) do
    remove_temp_directory
  end

  context 'when created' do
    it 'should raise an error if config file was not found' do
      lambda { GITRepoManager.new('config/non_existing_repos.yml') }.should raise_error()
    end
  end

  context 'when created with a specfic config file' do

    after(:all) do
      FileUtils.rm_r(LOCAL_REPOS)
    end

    manager = GITRepoManager.new(TEST_CONFIG, LOCAL_REPOS)

    it 'should load the configuration file and create a repositories directory' do
      manager.config_file.should == TEST_CONFIG
      File.exists?(manager.clone_path).should be_true
    end

    it 'should give a list of active submodules' do
      manager.submodules == [:test_git_submodule]
    end

    it 'should give access to config data' do
      manager.config_hash.should == {
        :using_submodule => {:uri => "file:///tmp/spec_testing/using_submodule"},
        :submodule       => {:submoduled_in => [:using_submodule],
                             :uri => "file:///tmp/spec_testing/submodule"}
      }
    end

    it 'should be able to clone projects that are using submodules' do
      manager.clone_repos_using_submodules
      File.exists?(File.join(manager.clone_path, 'using_submodule', '.git')).should be_true
      File.exists?(File.join(manager.clone_path, 'submodules')).should be_false
    end

    it 'should update submodules references for all projects with a branch named the same as the submodule' do
      #manager.update_submodule('test_git_submodule', 'master', "c5d7e75493b7e5297069bb732ca8260434a652e6")
    end
  end

end
