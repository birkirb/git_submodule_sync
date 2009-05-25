require 'lib/git_repo_manager'
require 'lib/global_logger'
require 'spec/spec_helper.rb'
require 'git'

describe GITRepoManager do

  LOCAL_REPOS = File.join(`pwd`.chomp, 'spec/files/test_repos')
  TEST_CONFIG = 'spec/files/config/repos.yml'

  TEST_REPO_USING_SUBMODULE = "file:///tmp/spec_testing/using_submodule"
  TEST_REPO_SUBMODULE = "file:///tmp/spec_testing/submodule"

  before(:all) do
    initalize_repos
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

    manager = GITRepoManager.new(TEST_CONFIG, LOCAL_REPOS)

    it 'should load the configuration file and create a repositories directory' do
      manager.config_file.should == TEST_CONFIG
      File.exists?(manager.clone_path).should be_true
    end

    it 'should give a list of active submodules' do
      manager.submodules.should == [:submodule]
    end

    it 'should give access to config data' do
      manager.config_hash.should == {
        :using_submodule => {:uri => TEST_REPO_USING_SUBMODULE},
        :submodule       => {:submoduled_in => [:using_submodule],
                             :uri => TEST_REPO_SUBMODULE}
      }
    end

    context 'and is receiving submodule updates' do

      after(:all) do
        FileUtils.rm_r(LOCAL_REPOS) if File.exists?(LOCAL_REPOS)
      end

      it 'should clone projects that are using submodules' do

        # Call update with irreleveant data, and make sure stuff is cloned
        manager.update_submodule('some_model', 'master', 'x')

        File.exists?(File.join(manager.clone_path, 'using_submodule', '.git')).should be_true
        File.exists?(File.join(manager.clone_path, 'submodules')).should be_false
        local_repo_clone = Git.open(File.join(LOCAL_REPOS, 'using_submodule'), :log => $logger)

        local_repo_clone.log.size.should == 2 # First and the submodule commit.
      end

      it 'should pull from projects already cloned so that it has the lastest commits locally' do

        `echo "New line in the readme file" >> #{@usesub_path}/README`
        @git_repo_using_sub.add('README')
        @git_repo_using_sub.commit('New line in readme')

        File.exists?(File.join(manager.clone_path, 'using_submodule', '.git')).should be_true
        manager.update_submodule('some_model', 'master', 'x')
        local_repo_clone = Git.open(File.join(LOCAL_REPOS, 'using_submodule'), :log => $logger)
        local_repo_clone.branch('origin/master').checkout

        local_repo_clone.log.size.should == 3 # First and the submodule commit.
        local_repo_clone.log.first.message.should == 'New line in readme'
      end

      it 'should auto commit an update to repositories using submodules' do
        commit = update_submodule

        manager.update_submodule(TEST_REPO_SUBMODULE, 'master', commit.sha)
        local_repo_clone = Git.open(File.join(LOCAL_REPOS, 'using_submodule'), :log => $logger)

        local_repo_clone.log.first.message.should == "Auto-updating submodule plugins/some_module to commit #{commit.sha}."
      end

      it 'should push auto commits to the remote repository' do
        commit = update_submodule

        manager.update_submodule(TEST_REPO_SUBMODULE, 'master', commit.sha)

        @git_repo_using_sub.log.first.message.should == "Auto-updating submodule plugins/some_module to commit #{commit.sha}."
      end

      it 'should work with http://github.com prefixes' do
        commit = update_submodule

        manager.update_submodule('http://github.com/tmp/spec_testing/submodule', 'master', commit.sha)
        local_repo_clone = Git.open(File.join(LOCAL_REPOS, 'using_submodule'), :log => $logger)

        local_repo_clone.log.first.message.should == "Auto-updating submodule plugins/some_module to commit #{commit.sha}."
      end

      it 'should work with git@github.com: prefixes' do
        commit = update_submodule

        manager.update_submodule('git@github.com:tmp/spec_testing/submodule', 'master', commit.sha)
        local_repo_clone = Git.open(File.join(LOCAL_REPOS, 'using_submodule'), :log => $logger)

        local_repo_clone.log.first.message.should == "Auto-updating submodule plugins/some_module to commit #{commit.sha}."
      end

      it 'should not do anything for different branches' do
        commit = update_submodule

        manager.update_submodule(TEST_REPO_SUBMODULE, 'stuff', commit.sha)
        local_repo_clone = Git.open(File.join(LOCAL_REPOS, 'using_submodule'), :log => $logger)

        local_repo_clone.log.first.message.should_not == "Auto-updating submodule plugins/some_module to commit #{commit.sha}."
      end

      it 'should create local copies of branches that exist remotely when they match the submodules branches' do
        @git_repo_sub.branch('testing').checkout
        `echo "Line for the testing branch." >> #{@sub_path}/README`
        @git_repo_sub.add('.')
        @git_repo_sub.commit('Testing line in readme')

        @git_repo_using_sub.branch('testing').checkout
        `echo "Line for the testing branch in the using submodule repository." >> #{@sub_path}/README`
        @git_repo_sub.add('.')
        @git_repo_sub.commit('Testing line in using submodule readme')

        commit = update_submodule
        manager.update_submodule(TEST_REPO_SUBMODULE, 'testing', commit.sha)
        local_repo_clone = Git.open(File.join(LOCAL_REPOS, 'using_submodule'), :log => $logger)
        local_repo_clone.checkout('testing')
        local_repo_clone.log.first.message.should == "Auto-updating submodule plugins/some_module to commit #{commit.sha}."
      end
    end
  end

end
