# Overview

github-branch-protector is a simple Azure Function (PowerShell Core) that listens for GitHub organization events to know when a repository has been created. When a repo is created, the function automates the protection of the master branch. A notification with an @mention in an issue within the repository outlines the protections that were added.

## Build Status
![CI](https://github.com/MarcusFellingOrganization/github-branch-protector/workflows/github-branch-protector/badge.svg)

## How it works
A function's project directory contains the files [host.json](https://docs.microsoft.com/en-us/azure/azure-functions/functions-host-json) and [local.settings.json](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=windows%2Ccsharp%2Cbash#local-settings-file), along with subfolders that contain the code for individual functions. In this project we have 1 function called GitHubEvent trigger. It contains [function.json](https://github.com/MarcusFellingOrganization/github-branch-protector/blob/master/GitHubEventTrigger/function.json) that holds the configuration metadata for the function, and a single script file [run.ps1](https://github.com/MarcusFellingOrganization/github-branch-protector/blob/master/GitHubEventTrigger/run.ps1) that contains the function code.

The function is triggered by an HTTP request from a GitHub webhook. When the function is triggered, it then executes [run.ps1](https://github.com/MarcusFellingOrganization/github-branch-protector/blob/master/GitHubEventTrigger/run.ps1). Run.ps1 contains the logic to look for a new repository creation from the webhook, if so, invoke GitHub branch API to update master branch's protection, then invoke GitHub issues API to create new issue containing response from adding protection. If event is not creation of new repository, the script does nothing.  Upon completion, a response is sent back to the GitHub webhook with the results.

![AzureFunctionDiagram.PNG](/docs/images/AzureFunctionDiagram.PNG)

For an example of the issue that is created, see here: https://github.com/MarcusFellingOrganization/test/issues/2

## How to get started
1. Clone repo to Visual Studio Code workspace 
2. [Sign in to Azure using Visual Studio Code](https://docs.microsoft.com/en-us/azure/azure-functions/functions-create-first-function-vs-code?pivots=programming-language-powershell#sign-in-to-azure)
3. [Publish the project to Azure](https://docs.microsoft.com/en-us/azure/azure-functions/functions-create-first-function-vs-code?pivots=programming-language-powershell#publish-the-project-to-azure)
4. [Add App Settings to Azure Functions](https://docs.microsoft.com/en-us/azure/azure-functions/functions-how-to-use-azure-function-app-settings): 
>- GITHUB_ORGANIZATION: Set the value to name of organization
>- PAT: Create and set value of GitHub [personal access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line)
>- GITHUB_WEBHOOKUSER: Set value to name of user who creates webhook in step 5 below
5. [Create a GitHub webwook](https://developer.github.com/webhooks/creating/) in the organization you'd like to protect. When creating the webhook scope it to repository events only. The payload url should be configured to point to the Azure Function trigger url that will look like: https://NAMEOFFUNCTION.azurewebsites.net/api/NAMEOFTRIGGER?code=*******
6. Create a new repository to test

## TO DO
- Add handling for repos with no master branch
- Prettify issue description by adding markdown to protection response
- Refactor by breaking into functions


