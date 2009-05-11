require 'rubygems'
require 'sinatra'
require 'json'
require 'logger'
require 'fileutils'

DATA=<<-EOF
{
  "before": "5aef35982fb2d34e9d9d4502f6ede1072793222d",
  "repository": {
    "url": "http://github.com/defunkt/github",
    "name": "github",
    "description": "You're lookin' at it.",
    "watchers": 5,
    "forks": 2,
    "private": 1,
    "owner": {
       "commits": [
    {
      "id": "41a212ee83ca127e3c8cf465891ab7216a705f59",
      "url": "http://github.com/defunkt/github/commit/41a212ee83ca127e3c8cf465891ab7216a705f59",
      "author": {
        "email": "chris@ozmm.org",
        "name": "Chris Wanstrath"
      },
      "message": "okay i give in",
      "timestamp": "2008-02-15T14:57:17-08:00",
      "added": ["filepath.rb"]
    },
    {
      "id": "de8251ff97ee194a289832576287d6f8ad74e3d0",
      "url": "http://github.com/defunkt/github/commit/de8251ff97ee194a289832576287d6f8ad74e3d0",
      "author": {
        "email": "chris@ozmm.org",
        "name": "Chris Wanstrath"
      },
      "message": "update pricing a tad",
      "timestamp": "2008-02-15T14:36:34-08:00"
    }
  ],
  "after": "de8251ff97ee194a289832576287d6f8ad74e3d0",
  "ref": "refs/heads/master"
}
EOF

log_dir = File.join(File.dirname(__FILE__), "log")
if !File.exist?(log_dir)
  FileUtils.mkdir_p(log_dir)
end
$logger = Logger.new(File.join(log_dir, "web_hook.log"))
$base_path = ''

def save_head(branch, commit)
  if File.exist?(@git)
    branch_dir = File.join(@git, 'kwala', 'branches', branch)
    FileUtils.mkdir_p(branch_dir) if !File.exist?(branch_dir)
    File.open(File.join(branch_dir, 'HEAD'), 'w+') do |file|
      file.write(commit)
    end
  end
end

def save_tested(branch, commit)
  if File.exist?(@git)
    branch_dir = File.join(@git, 'kwala', 'branches', branch)
    FileUtils.mkdir_p(branch_dir) if !File.exist?(branch_dir)
    File.open(File.join(branch_dir, 'TESTED'), 'w+') do |file|
      file.write(commit)
    end
  end
end

post '/' do
#  push = JSON.parse(params[:payload])
  push = JSON.parse(DATA)

  $logger.info "REQUEST START"
  $logger.info "Before : #{push["before"]}"
  $logger.info "After : #{push["after"]}"
  $logger.info "Commits\n" + push["commits"].map { |h| "#{h["author"]["name"]} : #{h["url"]}" }.join("\n")
  $logger.info "Rep : " + push["repository"]["url"] + " : " + push["repository"]["name"]
  $logger.info "Branch : #{push["ref"]}"
  $logger.info push.inspect
  $logger.info "REQUEST END"

  "Thanks"
end
