Given /^I have a config file "(.+)"/ do |config_path|
  @config_file = config_path
  File.exists?(config_path).should be_true
end

Given /^therein a project called "([^\"]*)" has a submodule called "([^\"]*)"$/ do |repo_with_submodule, submodule_repo|
  config_hash = YAML.load_file(@config_file)

  config_hash[repo_with_submodule].should_not be_nil
  config_hash[submodule_repo].should_not be_nil
end

Then /^a monitoring server should set be set up on path "([^\"]*)"\.$/ do |path|
  @path = path
  visit(path)
  response_body.should_not be_nil
end

When /^sent a "([^\"]*)" request$/ do |method|
  visit(@path, method)
end

Then /^it should return a (\d+) saying "([^\"]*)"\.$/ do |status, message|
  response_code.should == status.to_i
  response_body.should == message
end

When /^sent a "([^\"]*)" request without a payload$/ do |method|
  visit(@path, method)
end

Then /^it should return (\d+) saying "([^\"]*)"\.$/ do |status, message|
  response_code.should == status.to_i
  response_body.should == message
end

When /^sent a "([^\"]*)" request with a proper payload:$/ do |method, proper_payload|
  visit(@path, method, :payload => proper_payload.gsub("COMMITISH", @commitish))
end

Then /^it should return a (\d+), having updated the "([^\"]*)", with the message:$/ do |status, submodule, message|
  response_code.should == status.to_i
  response_body.should == message.gsub("COMMITISH", @commitish)
end
