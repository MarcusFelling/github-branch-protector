# new-repo-branch-protection
A simple web service that listens for organization events to know when a repository has been created. When a repo is created, this automates the protection of the master branch. A notification with an @mention in an issue within the repository outlines the protections that were added.


References
https://github.com/aspnet/WebHooks/tree/master/samples/GitHubCoreReceiver
-https://docs.microsoft.com/en-us/aspnet/webhooks/receiving/receivers
