#Then let's add some manual write-progress
Write-Progress -Activity "Running your script" -Status "Sleeping for a bit" -PercentComplete 10
Start-Sleep -Seconds 5

Write-Progress -Activity "Running your script" -Status "Sleeping for a bit" -PercentComplete 20
Start-Sleep -Seconds 5

Write-Progress -Activity "Running your script" -Status "Getting processes" -PercentComplete 40
$processes = Get-Process

Write-Progress -Activity "Running your script" -Status "Sleeping for a bit" -PercentComplete 50
Start-Sleep -Seconds 5

Write-Progress -Activity "Running your script" -Status "Sleeping for a bit" -PercentComplete 60
Start-Sleep -Seconds 5

Write-Progress -Activity "Running your script" -Status "Getting services" -PercentComplete 80
$services = Get-Service

Write-Progress -Activity "Running your script" -Status "Sleeping for a bit" -PercentComplete 90
Start-Sleep -Seconds 5

Write-Progress -Activity "Running your script" -Status "Sleeping for a bit" -Completed