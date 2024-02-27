#Now let's get to the fun part, foreach looping it and automating the progress bar
Write-Progress -Activity "Running your script" -Status "Sleeping for a bit" -Id 1 -PercentComplete 10
Start-Sleep -Seconds 5

Write-Progress -Activity "Running your script" -Status "Sleeping for a bit" -Id 1 -PercentComplete 20
Start-Sleep -Seconds 5

Write-Progress -Activity "Running your script" -Status "Getting processes" -Id 1 -PercentComplete 40
Write-Progress -Activity "Getting all processes" -Status "Getting processes" -Id 2 -ParentId 1 -PercentComplete 1
$processes = Get-Process
$progress = 1
foreach ($process in $processes) {
    Write-Progress -Activity "Getting all processes" -Status "Got $($process.name)" -Id 2 -ParentId 1 -PercentComplete ($progress/$processes.count*100)
    Start-Sleep -Milliseconds 100
    $progress++
}
#Write-Progress -Activity "Getting all processes" -Status "Got all the processes, now sleeping for a bit" -Id 2 -ParentId 1 -PercentComplete 80
#Start-Sleep -Seconds 5
Write-Progress -Activity "Getting all processes" -Status "Got all the processes" -Id 2 -ParentId 1 -Completed

Write-Progress -Activity "Running your script" -Status "Sleeping for a bit" -Id 1 -PercentComplete 50
Start-Sleep -Seconds 5

Write-Progress -Activity "Running your script" -Status "Sleeping for a bit" -Id 1 -PercentComplete 60
Start-Sleep -Seconds 5

Write-Progress -Activity "Running your script" -Status "Getting services" -Id 1 -PercentComplete 80
Write-Progress -Activity "Getting all services" -Status "Getting services" -Id 2 -ParentId 1 -PercentComplete 10
$services = Get-Service
$progress = 1
foreach ($Service in $Services) {
    Write-Progress -Activity "Getting all services" -Status "Got $($Service.name)" -Id 2 -ParentId 1 -PercentComplete ($progress/$Services.count*100)
    Start-Sleep -Milliseconds 100
    $progress++
}
#Write-Progress -Activity "Getting all services" -Status "Got all the services, now sleeping for a bit" -Id 2 -ParentId 1 -PercentComplete 80
#Start-Sleep -Seconds 5
Write-Progress -Activity "Getting all services" -Status "Got all the services" -Id 2 -ParentId 1 -Completed

Write-Progress -Activity "Running your script" -Status "Sleeping for a bit" -Id 1 -PercentComplete 90
Start-Sleep -Seconds 5

Write-Progress -Activity "Running your script" -Status "Sleeping for a bit" -Id 1 -Completed
Write-Progress -Activity "Running your script" -Status "Sleeping for a bit" -Id 2 -Completed