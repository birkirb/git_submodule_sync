Feature: commit_monitor
  A GitHub hook that monitors repositories that are submodules and updates repositories containing that submodule, such that
  containg repositories having the same branch as the submodule will be updated to the latest commit of the submodule.

  Scenario: submodule
    Given I have a config file "spec/files/config/repos.yml" setting up repos to track,
    And therein a project called "using_submodule" has a submodule called "submodule"
    Then a monitoring server should set be set up on path "/submodule".
    When sent a "get" request
    Then it should return a 403 saying "Payload only accepted via POST".
    When sent a "post" request without a payload
    Then it should return 400 saying "Payload missing".
    When sent a "post" request with a proper payload:
      """
    {
      "before": "5aef35982fb2d34e9d9d4502f6ede1072793222d",
      "repository": {
        "url": "http://github.com/tmp/spec_testing/submodule",
        "name": "github",
        "description": "You're lookin' at it.",
        "watchers": 5,
        "forks": 2,
        "private": 1,
        "owner": {
          "email": "chris@ozmm.org",
          "name": "defunkt"
        }
      },
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
      "after": "COMMITISH",
      "ref": "refs/heads/master"
    }
      """
    Then it should return a 200, having updated "spec_testing/submodule", with the message:
      """
      Auto-updating submodule to commit spec_testing/submodule@COMMITISH.
      """
