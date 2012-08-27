Given /^a running monitor that we'd like to ping for monitoring$/ do
  # Good
end

When /^a "(.*?)" request is made to path "(.*?)"$/ do |method, path|
  @path = path
  visit(path)
  response_body.should_not be_nil
end
