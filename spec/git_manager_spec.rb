require 'lib/git_repo_manager'

describe GITRepoManager, 'when created' do
  it "should have a default configuration file and create a repositories directory" do
    manager = GITRepoManager.new
    manager.config.should eql('config/repos.yml')
    File.exists?(GITRepoManager::REPOSITORIES).should be_true
  end
end

describe GITRepoManager do
  config = 'spec/data/projects.yml'
  manager = GITRepoManager.new(config)

  it 'should load a specified configuration file' do
    manager.config.should == config
  end

  it 'should give access to project data' do
    manager.repos.should == {
        :smart_core   => {:submoduled_in => [:smart_mobile, :smart_api],
                          :url => "git@github.com:cerego/smart_core.git"},
        :smart_api    => {:url => "git@github.com:cerego/smart_api.git"},
        :smart_mobile => {:url => "git@github.com:cerego/smart_mobile.git"}
    }
  end

  it 'should be able to clone projects using submodules' do
    manager.clone_repos_using_submodules
    File.exists?(File.join(GITRepoManager::REPOSITORIES, 'smart_api', '.git')).should be_true
    File.exists?(File.join(GITRepoManager::REPOSITORIES, 'smart_core')).should be_false
  end
end
