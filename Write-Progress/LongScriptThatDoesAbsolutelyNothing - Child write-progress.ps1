#Now let's add in another progress bar, as a child, for the get-process and get-service
Write-Progress -Activity "Running your script" -Status "Sleeping for a bit" -Id 1 -PercentComplete 10
Start-Sleep -Seconds 5

Write-Progress -Activity "Running your script" -Status "Sleeping for a bit" -Id 1 -PercentComplete 20
Start-Sleep -Seconds 5

Write-Progress -Activity "Running your script" -Status "Getting processes" -Id 1 -PercentComplete 40
Write-Progress -Activity "Getting all processes" -Status "Getting processes" -Id 2 -ParentId 1 -PercentComplete 10
$processes = Get-Process
Write-Progress -Activity "Getting all processes" -Status "Got all the processes, now sleeping for a bit" -Id 2 -ParentId 1 -PercentComplete 80
Start-Sleep -Seconds 5
Write-Progress -Activity "Getting all processes" -Status "Got all the processes, now sleeping for a bit" -Id 2 -ParentId 1 -Completed

Write-Progress -Activity "Running your script" -Status "Sleeping for a bit" -Id 1 -PercentComplete 50
Start-Sleep -Seconds 5

Write-Progress -Activity "Running your script" -Status "Sleeping for a bit" -Id 1 -PercentComplete 60
Start-Sleep -Seconds 5

Write-Progress -Activity "Running your script" -Status "Getting services" -Id 1 -PercentComplete 80
Write-Progress -Activity "Getting all services" -Status "Getting services" -Id 2 -ParentId 1 -PercentComplete 10
$services = Get-Service
Write-Progress -Activity "Getting all services" -Status "Got all the services, now sleeping for a bit" -Id 2 -ParentId 1 -PercentComplete 80
Start-Sleep -Seconds 5

Write-Progress -Activity "Running your script" -Status "Sleeping for a bit" -Id 1 -PercentComplete 90
Start-Sleep -Seconds 5

Write-Progress -Activity "Running your script" -Status "Sleeping for a bit" -Id 1 -Completed
Write-Progress -Activity "Running your script" -Status "Sleeping for a bit" -Id 2 -Completed