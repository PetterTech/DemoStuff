#Getting things to loop through
$aFewNumbers = 1..1337
$services = Get-Service

#PoC using the statement
foreach ($number in $aFewNumbers) {
    $number.GetType()
}

foreach ($service in $services) {
    Stop-Service $service
}

foreach ($process in (Get-Process)) {
    Stop-Process $process
}

#PoC using the method
$aFewNumbers.ForEach({
    $_.GetType()
})

$services.ForEach({Stop-Service $_})

(Get-Process).ForEach({Stop-Process $_})

(Get-Process).ForEach('Kill')

(Get-Process).ForEach({Write-Host "Hi" -ForegroundColor Green})

#PoC using the alias
$aFewNumbers | foreach {
    $_.GetType()
}

$aFewNumbers | foreach {$_.GetType()}

$services | foreach {Stop-Service $_}

Get-Process | foreach {Stop-Process $_}

#PoC using the cmdlet
$aFewNumbers | ForEach-Object {
    $_.GetType()
}

$aFewNumbers | ForEach-Object {$_.GetType()}

$services | ForEach-Object {Stop-Service $_}

Get-Process | ForEach-Object {Stop-Process $_}