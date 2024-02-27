#Getting something to loop through
$aLotOfNumbers = 1..14748360

#Measure the statement 5 times
$i = 1
Write-Host "The statement:"
while ($i -le 5) {
    Measure-Command {foreach ($number in $aLotOfNumbers) {$number.GetType()}} | Select-Object TotalSeconds
    $i++
}

#Measure the method 5 times
$i = 1
Write-Host "The method:"
while ($i -le 5) {
    Measure-Command {$aLotOfNumbers.ForEach({$_.GetType()})} | Select-Object TotalSeconds
    $i++
}

#Measure the alias 5 times
$i = 1
Write-Host "The alias:"
while ($i -le 5) {
    Measure-Command {$aLotOfNumbers | foreach {$_.GetType()}} | Select-Object TotalSeconds
    $i++
}

#Measure the cmdlet 5 times
$i = 1
Write-Host "The cmdlet:"
while ($i -le 5) {
    Measure-Command {$aLotOfNumbers | ForEach-Object {$_.GetType()}} | Select-Object TotalSeconds
    $i++
}

#Measure the statement once
Measure-Command {
    foreach ($number in $aLotOfNumbers) {
        $number.GetType()
    }
}

#Measure the method once
Measure-Command {
    $aLotOfNumbers.ForEach({
        $_.GetType()
    })
}

#Measure the alias once
Measure-Command {
    $aLotOfNumbers | foreach {
        $_.GetType()
    }  
}

#Measure the cmdlet once
Measure-Command {
    $aLotOfNumbers | ForEach-Object {
        $_.GetType()
    }
}


#######
#
# Where the method shines
#
#######

# Let's start a few processes
1..100 | ForEach-Object {start-process notepad.exe}

# Then let's kill them with the statement
foreach ($process in (Get-Process -Name notepad)) {
    Stop-Process $process
}

# Now let's kill them with the method
(Get-Process -Name notepad).foreach('Kill')

# For fun, let's kill them with the cmdlet
Get-Process -Name notepad | ForEach-Object {Stop-Process $_}

#
# Now let's measure the time it takes
#

# With the statement
1..100 | ForEach-Object {start-process notepad.exe}
Measure-Command {
    foreach ($process in (Get-Process -Name notepad)) {
        Stop-Process $process
    }
}

# With the method
1..100 | ForEach-Object {start-process notepad.exe}
Measure-Command {
    (Get-Process -Name notepad).foreach('Kill')
}

# With the cmdlet
1..100 | ForEach-Object {start-process notepad.exe}
Measure-Command {
    Get-Process -Name notepad | ForEach-Object {Stop-Process $_}
}