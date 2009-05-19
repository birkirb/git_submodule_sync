require 'lib/git_repo_manager'

describe GITRepoManager, 'when created' do
  it 'should raise an error if config file was not found' do
    lambda { GITRepoManager.new('config/non_existing_repos.yml') }.should raise_error()
  end
end

describe GITRepoManager do
  config = 'spec/data/config/repos.yml'
  local_repos = File.join('/home/birkirb/workspace/git/git_submodule_sync/spec/data/test_repos')
  manager = GITRepoManager.new(config, local_repos)

  it 'should load a specified configuration file and create a repositories directory' do
    manager.config_file.should == config
    File.exists?(manager.clone_path).should be_true
  end

  it 'should give a list of active submodules' do
    manager.submodules == [:test_git_submodule]
  end

  it 'should give access to config data' do
    manager.config_hash.should == {
      :test_git_using_submodule_1 => {:uri => "git@github.com:birkirb/test_git_using_submodule_1.git"},
      :test_git_submodule         => {:submoduled_in => [:test_git_using_submodule_1],
                                      :uri => "git@github.com:birkirb/test_git_submodule.git"}
    }
  end

  it 'should be able to clone projects that are using submodules' do
    manager.clone_repos_using_submodules
    File.exists?(File.join(manager.clone_path, 'test_git_using_submodule_1', '.git')).should be_true
    File.exists?(File.join(manager.clone_path, 'test_git_submodule')).should be_false
  end

  it 'should update submodules references for all projects with a branch named the same as the submodule' do
    manager.update_submodule('test_git_submodule', 'master', "c5d7e75493b7e5297069bb732ca8260434a652e6")
  end
end
