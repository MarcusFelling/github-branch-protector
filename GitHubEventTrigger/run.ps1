
using namespace System.Net

# Input bindings are passed in via param block.
# Request comes from GitHub webhook
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Parse the body of the request for below criteria
if  (($Request.Body.action -eq "created") -AND # Check for GitHub repository action "created" https://developer.github.com/webhooks/event-payloads/#repository
    ($Request.Body.organization.login -eq $env:GITHUB_ORGANIZATION) -AND # Only allow requests from specified GitHub org, value set in function App Settings
    ($Request.Body.sender.login -eq $env:GITHUB_WEBHOOKUSER)){ # Only allow requests from specified GitHub user, value set in function App Settings
    
  # Begin creation of branch protection on master branch for new repository 
  # TODO: Move into function
  try {  

    # Add logging to response body back to webhook  
    $body = "Adding master branch protection on new repo: " + $Request.Body.repository.name + "..."

    # Construct body of request to create branch protection
    $branchprotectionbody = @"
    {
      "protected": true,
      "enforce_admins": null,
      "required_pull_request_reviews": null,
      "required_status_checks": null,
      "restrictions": null,
      "protection": {
        "enabled": true,
        "required_status_checks": {
          "enforcement_level": "off",
          "contexts": [

          ]
        }
      }
    }
"@   
        # Invoke request PUT /repos/:owner/:repo/branches/:branch/protection
        # Use Personal Access Token (PAT) for auth, set as app setting
        # TODO: Add check for master branch before adding protection
        $uri = $Request.Body.repository.url
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$env:PAT))) # Base64-encodes the Personal Access Token (PAT) appropriately
        $response = Invoke-RestMethod -uri "$uri/branches/master/protection" -Method Put -ContentType "application/vnd.github.luke-cage-preview+json" -Body $branchprotectionbody -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
        
        # HTTP Status code to send back to the GitHub Webhook
        $StatusCode = [HttpStatusCode]::OK        
  }
  catch {
      Write-Host "Failed to create branch protection"
      $StatusCode = [HttpStatusCode]::BadRequest
  }

  # Notify GITHUB_WEBHOOKUSER with an @mention in an issue within the repository that outlines the protections that were added.
  # TODO: Add a check if issues are disabled in the repository, the API returns a 410 Gone status.
  try {

    # Add logging to response body back to webhook  
    $body = $body + "Creating issue with branch protection details" + "..."

    # Construct body of request to create issue
    $issuebody = @"
    {
      "title": "Master branch protection added",
      "body": "@MarcusFelling the following protections were added: $response",
      "assignees": [
        "$env:GITHUB_WEBHOOKUSER"
      ]
    }
"@       
    # Invoke request POST /repos/:owner/:repo/issues
    # Use Personal Access Token (PAT) for auth, set as app setting 
    $uri = $Request.Body.repository.url
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$env:PAT))) # Base64-encodes the Personal Access Token (PAT) appropriately
    $response = Invoke-RestMethod -uri "$uri/issues" -Method Post -ContentType "application/vnd.github.luke-cage-preview+json" -Body $issuebody -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}          

    # HTTP Status code to send back to the GitHub Webhook
    $StatusCode = [HttpStatusCode]::OK    
  }
  catch {
    Write-Host "Failed to create issue"
    $StatusCode = [HttpStatusCode]::BadRequest
  }
  
}

# If the webhoook event is not creation of new repo, or if it's from another user/org, do nothing.
else{
    $body = "Nothing to do here..."
    # HTTP Status code to send back to the GitHub Webhook
    $StatusCode = [HttpStatusCode]::OK
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $StatusCode
    Body = $body
})


