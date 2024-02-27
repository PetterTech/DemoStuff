function New-AzureServer
    {
    <#
    .SYNOPSIS
    Deploys VM in Azure
    .DESCRIPTION
    Will deploy VM in Azure based on input and certain standards.
    .PARAMETER Name
    The name for the VM. Should always start with "AZ-" followed by a three-letter abbriviation for the region, three letters describing function
    and then two numbers. For example AZ-WEU-APP01 for an application server in Europe.
    .PARAMETER Region
    The region the VM should be deployed to. Must be within a predefined set. Selecting Europe will choose West Europe as Azure region, America will
    choose East US, Asia will choose Southeast Asia.
    .PARAMETER Size
    The size for the VM. Selection is based on standards. For more info on VM sizes in Azure, refer to https://docs.microsoft.com/en-us/azure/virtual-machines/sizes
    Can be changed manually after deployment.
    .PARAMETER OS
    The operating system for the VM. Follows standards and therefore your only choice is Windows or Linux, more specific OS/distro will be chosen for you.
    .EXAMPLE
    New-AzureServer -Name "AZ-WEU-APP01" -Region Europe -Size D2s -OS Windows
    Will deploy a VM named AZ-WEU-APP01 in the West Europe region in Azure. Size will be D2s
    .LINK
    https://pettertech.com
    #>    
        [CmdletBinding()] 
            Param (
                [Parameter(Mandatory=$True,Position=0,HelpMessage='Name for the VM')]
                [ValidatePattern('^az-.*')]
                [string]$Name,
                [Parameter(Mandatory=$True,Position=1,HelpMessage='Region where the VM should be deployed')]
                [ValidateSet('Europe','America','Asia')]
                [string]$Region,
                [Parameter(Mandatory=$True,Position=2,HelpMessage='Size for the VM')]
                [ValidateSet('B2s','D2s','D4s','E4s','F2s')]
                [string]$Size,
                [Parameter(Mandatory=$True,Position=3,HelpMessage='OS the VM should have')]
                [ValidateSet('Windows','Linux')]
                [string]$OS
                )
    Begin {
	    #Verify that name is within standards and matches region
        Write-Progress -Activity "Deploying Azure server" -Status "In preparation phase" -CurrentOperation "Validating that VM name is within standards"
        Write-Verbose "Input region was $($Region) and input name was $($Name)"
        switch ($Region) {
            "America" {if (!($Name -like "az-eus-*")) {Write-Error "VM name does not comply with naming standard" -ErrorAction Stop}}
            "Europe" {if (!($Name -like "az-weu-*")) {Write-Error "VM name does not comply with naming standard" -ErrorAction Stop}}
            "Asia" {if (!($Name -like "az-sea-*")) {Write-Error "VM name does not comply with naming standard" -ErrorAction Stop}}
        }
        Write-Progress -Activity "Deploying Azure server" -Status "In preparation phase" -CurrentOperation "Validating that VM name is within standards" -Completed

        #Make sure servername is in uppercase
        Write-Progress -Activity "Deploying Azure server" -Status "In preparation phase" -CurrentOperation "Converting servername to uppercase"
        try {
            Write-Verbose "Name before conversion: $($Name)"
            $Name = $Name.ToUpper()
            Write-Verbose "Name after conversion: $($Name)"
        }
        catch {
            Write-Verbose "Something failed during name conversion"
            $Error[0] | Out-Host
            Write-Error "Failed to convert VM name to uppercase" -ErrorAction Stop
        }
        Write-Progress -Activity "Deploying Azure server" -Status "In preparation phase" -CurrentOperation "Converting servername to uppercase" -Completed

        #Convert size to Azure readable format
        Write-Progress -Activity "Deploying Azure server" -Status "In preparation phase" -CurrentOperation "Converting size to Azure readable size"
        Write-Verbose "Converting size to Azure formatted size name. Input: $($Size)"
        switch ($Size) {
            "B2s" {$VMSize =  "Standard_B2s" }
            "D2s" {$VMSize =  "Standard_D2s_v4" }
            "D4s" {$VMSize =  "Standard_D4s_v4" }
            "E4s" {$VMSize =  "Standard_E4s_v4" }
            "F2s" {$VMSize =  "Standard_F2s_v2" }
            Default {$VMSize = "Borked"}
        }
        Write-Verbose "Done converting size to Azure formatted size name. Output: $($VMsize)"

        if ($VMSize -eq "Borked") {
            Write-Error "Failed to match size to Azure readable size" -ErrorAction Stop
        }
        Write-Progress -Activity "Deploying Azure server" -Status "In preparation phase" -CurrentOperation "Converting size to Azure readable size" -Completed

        #Get username
        $DeployingUser = [Environment]::UserName

        #Connect to Azure
        Write-Progress -Activity "Deploying Azure server" -Status "In preparation phase" -CurrentOperation "Connecting to Azure"
        try {
            Write-Verbose "Trying to connect to Azure"
            Connect-AzAccount -ErrorAction Stop | Out-Null
            Write-Verbose "Attempt complete"
        }
        catch {
            Write-Verbose "Something failed during connection to Azure"
            $Error[0] | Out-Host
            Write-Error "Failed to connect to Azure" -ErrorAction Stop
        }
        Write-Progress -Activity "Deploying Azure server" -Status "In preparation phase" -CurrentOperation "Connecting to Azure" -Completed

        #Checking if servername is already in use
        Write-Progress -Activity "Deploying Azure server" -Status "In preparation phase" -CurrentOperation "Verifying availability of servername"
        try {
            Write-Verbose "Checking to see if $($Name) is already taken"
            if (($null -eq (Get-AzVM -Name $Name))) {
                Write-Verbose "VM name is available"
            }
            else {
                $takenVM = Get-AzVM -Name $Name
                Write-Verbose "Servername is taken by $($takenVM.Id)"
                Write-Error "Servername is already in use in Azure" -ErrorAction Stop
            }
        }
        catch {
            Write-Error "Servername is taken" -ErrorAction Stop
        }
        Write-Progress -Activity "Deploying Azure server" -Status "In preparation phase" -CurrentOperation "Verifying availability of servername" -Completed

        #Get correct region as a variabe
        Write-Progress -Activity "Deploying Azure server" -Status "In preparation phase" -CurrentOperation "Getting correct Azure region"
        try {
            Write-Verbose "Getting all Azure regions"
            $AllAzRegions = Get-AzLocation -ErrorAction Stop
        }
        catch {
            Write-Verbose "Something failed during Azure region getting"
            $Error[0] | Out-Host
            Write-Error "Failed to get all Azure regions" -ErrorAction Stop                
        }

        try {
            Write-Verbose "Getting correct region based on input. Input was: $($Region)"
            switch ($Region) {
                "America" {$AzRegion = $AllAzRegions | Where-Object {$_.Location -eq "eastus"}}
                "Europe" {$AzRegion = $AllAzRegions | Where-Object {$_.Location -eq "westeurope"}}
                "Asia" {$AzRegion = $AllAzRegions | Where-Object {$_.Location -eq "southeastasia"}}
                Default {$AzRegion = "Borked"}
            }
            Write-Verbose "Got this region: $($AzRegion.Location)"
            if ($AzRegion -eq "Borked") {
                Write-Error "Failed to get correct region" -ErrorAction Stop
            }            
        }
        catch {
            Write-Verbose "Something failed during region getting"
            $Error[0] | Out-Host
            Write-Error "Failed to get correct region" -ErrorAction Stop
        }
        Write-Progress -Activity "Deploying Azure server" -Status "In preparation phase" -CurrentOperation "Getting correct Azure region" -Completed

        #Get correct vNet based on region
        Write-Progress -Activity "Deploying Azure server" -Status "In preparation phase" -CurrentOperation "Getting correct vNet"
        try {
            Write-Verbose "Getting correct vNet based on input. Input was: $($Region)"
            switch ($Region) {
                "America" {$vNet = Get-AzVirtualNetwork -Name vnet-americas}
                "Europe" {$vNet = Get-AzVirtualNetwork -Name vnet-europe}
                "Asia" {$vNet = Get-AzVirtualNetwork -Name vnet-asia}
            }
            Write-Verbose "vNet gotten: $($vNet.Name)"
            if ($null -eq $vNet) {
                Write-Error "Failed to match region to vNet" -ErrorAction Stop
            }
        }
        catch {
            Write-Verbose "Something failed during vNet getting"
            $Error[0] | Out-Host
            Write-Error "Failed to get correct vNet" -ErrorAction Stop          
        }
        Write-Progress -Activity "Deploying Azure server" -Status "In preparation phase" -CurrentOperation "Getting correct vNet" -Completed

        #Get subnet
        Write-Progress -Activity "Deploying Azure server" -Status "In preparation phase" -CurrentOperation "Getting correct subnet"
        try {
            Write-Verbose "Getting correct subnet, based on input. Input was: $($vNet.Name)"
            $subnet = $vNet | Get-AzVirtualNetworkSubnetConfig -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to get subnet" -ErrorAction Stop
        }
        Write-Progress -Activity "Deploying Azure server" -Status "In preparation phase" -CurrentOperation "Getting correct subnet" -Completed

        #Get correct resource group based on vNet
        Write-Progress -Activity "Deploying Azure server" -Status "In preparation phase" -CurrentOperation "Getting target resource"
        try {
            Write-Verbose "Getting target resource group, based on vNet resourcegroup. Input: $($vNet.ResourceGroupName)"
            $targetResourceGroup = Get-AzResourceGroup -Name $vNet.ResourceGroupName -ErrorAction Stop
            Write-Verbose "Got this resourcegroup: $($targetResourceGroup.ResourceGroupName)"
        }
        catch {
            Write-Verbose "Something failed during resource group getting"
            $Error[0] | Out-Host
            Write-Error "Failed to get correct resource group" -ErrorAction Stop
        }
        Write-Progress -Activity "Deploying Azure server" -Status "In preparation phase" -CurrentOperation "Getting target resource" -Completed

        #Get correct VM image SKU
        Write-Progress -Activity "Deploying Azure server" -Status "In preparation phase" -CurrentOperation "Getting correct VM image SKU"
        try {
            switch ($OS) {
                "Windows" {$ImageSKU = Get-AzVMImage -Location $AzRegion.Location -PublisherName "microsoftWindowsServer" -Offer "windowsserver" -Skus "2022-datacenter-g2" | Select-Object -Last 1}
                "Linux" {$ImageSKU = Get-AzVMImage -Location $AzRegion.Location -PublisherName "Canonical" -Offer "0001-com-ubuntu-server-focal" -Skus "20_04-lts-gen2" | Select-Object -Last 1}
                Default {$ImageSKU = "Borked"}
            }
            if ($ImageSKU -eq "Borked") {
                Write-Error "Failed to match OS to image" -ErrorAction Stop
            }            
        }
        catch {
            Write-Verbose "Something failed during image getting"
            $Error[0] | Out-Host
            Write-Error "Failed to get correct image"            
        }
        Write-Progress -Activity "Deploying Azure server" -Status "In preparation phase" -CurrentOperation "Getting correct VM image SKU" -Completed
        
    }

    Process {
        #Converting default password to secure string
        Write-Progress -Activity "Deploying Azure server" -Status "In deployment phase" -CurrentOperation "Converting default password to secure string"
        try {
            $Password = "ThisIsMySecretPassw0rd!" | ConvertTo-SecureString -AsPlainText -Force -ErrorAction Stop
        }
        catch {
            Write-Verbose "Something failed during convertion of password to secure string"
            $Error[0] | Out-Host
            Write-Error "Failed to convert password to secure string"   
        }
        Write-Progress -Activity "Deploying Azure server" -Status "In deployment phase" -CurrentOperation "Converting default password to secure string" -Completed

        #Deploy vm
        Write-Progress -Activity "Deploying Azure server" -Status "In deployment phase" -CurrentOperation "Running deployment"
        try {
          New-AzResourceGroupDeployment -ResourceGroupName $targetResourceGroup.ResourceGroupName -TemplateFile .\main.bicep `
           -adminUsername "Petter" `
           -adminPassword $Password `
           -vmName $Name `
           -location $AzRegion.DisplayName `
           -deployingUser $DeployingUser `
           -vmSize $VMSize `
           -imageOffer $ImageSKU.Offer `
           -imageSku $ImageSKU.skus `
           -imageVersion $ImageSKU.Version `
           -imagePublisher $ImageSKU.PublisherName `
           -subnetID $subnet.Id `
           -ErrorAction Stop
        }
        catch {
          $Error[0] | Out-Host
          Write-Error "Deployment failed"  
        }
        Write-Progress -Activity "Deploying Azure server" -Status "In deployment phase" -CurrentOperation "Running deployment" -Completed
    }

    End {
        #Disconnect from Azure
        Write-Progress -Activity "Deploying Azure server" -Status "In cleanup phase" -CurrentOperation "Disconnecting from Azure"
        try {
        Disconnect-AzAccount -ErrorAction Stop | Out-Null
        }
        catch {
        }
        Write-Progress -Activity "Deploying Azure server" -Status "In cleanup phase" -CurrentOperation "Disconnecting from Azure" -Completed
    }
}