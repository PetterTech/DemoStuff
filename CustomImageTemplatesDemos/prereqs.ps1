<#
.Synopsis
This script takes care of the prereqs for Custom Image Templates
.Description
This script will do the following:
Register necessary resource providers
Create a user-assigned managed identity
Create a custom role in Azure
Assign the custom role to the managed identity
Create Azure Compute Gallery with 1 VM image definition
.Parameter ResourceGroupName
Name of the resource group where the resources will be created
.Example
prereqs.ps1 -ResourceGroupName "MyResourceGroup"
Registers resource providers on the subscription in current context, creates a user-assigned managed identity named CustomImageTemplateIdentity, creates a custom role in Azure named CustomImageTemplateRole, assigns the custom role to the managed identity and creates an Azure Compute Gallery named CustomImageGallery with 1 VM image definition named CustomImageDefinition
.Link
https://github.com/PetterTech/DemoStuff
#>
[CmdletBinding()] 
    Param (
        [ValidateScript({
            Get-AzResourceGroup -Name $_ -ErrorAction Stop
            }
        )]
        [Parameter(Mandatory=$True,Position=0)][string]$ResourceGroupName
    )

Begin {
    Write-Progress -Activity "Checking script prerequisites" -Status "Checking if necessary modules are installed" -PercentComplete 5 -Id 1 -ErrorAction SilentlyContinue

    # Check is necessary modules are installed
    try {
        $currentVerbosePreference = $VerbosePreference
        $VerbosePreference = "SilentlyContinue"
        Import-Module Az.Accounts -ErrorAction Stop
        Import-Module Az.Compute -ErrorAction Stop
        Import-Module Az.Resources -ErrorAction Stop
        Import-Module Az.ManagedServiceIdentity -ErrorAction Stop
        $VerbosePreference = $currentVerbosePreference
    }
    catch {
        Write-Verbose $Error[0]
        Write-Error "Failed to import necessary modules. Please make sure you have correct modules installed"
        exit
    }

    Write-Progress -Activity "Checking script prerequisites" -Status "Checking if connected to Azure" -PercentComplete 10 -Id 1 -ErrorAction SilentlyContinue
    # Check is connected to Azure
    try {
        Get-AzSubscription -ErrorAction Stop | Out-Null
    }
    catch {
        write-verbose $Error[0]
        Write-Error "Not connected to Azure. Please connect using Connect-AzAccount"
        exit
    }

    Write-Progress -Activity "Checking script prerequisites" -Status "Checking if user has necessary permissions" -PercentComplete 15 -Id 1 -ErrorAction SilentlyContinue
    # Check if the user has the necessary permissions
    # Grab current context
    try {
        $Context = Get-AzContext
    }
    catch {
        write-verbose $Error[0]
        Write-Error "Failed to get current context. Please make sure you are connected to Azure"
        exit
    }

    # Grab all the roles the user has on the subscription
    try {
        $RoleAssignments = Get-AzRoleAssignment -SignInName $Context.Account -Scope "/subscriptions/$($Context.subscription)"
    }
    catch {
        Write-Verbose $Error[0]
        Write-Error "Failed to get role assignments."
        exit
    }

    # Verify that user has either owner or User Access Administrator role + Contributor on the subscription
    try {
        if ($null -eq ($RoleAssignments | Where-Object { ($_.RoleDefinitionName -contains "Owner") -or ($_.RoleDefinitionName -contains "User Access Administrator" -and $_.RoleDefinitionName -contains "Contributor" )})) {
            Write-Error "Correct role not found. Please make sure you have either Owner or User Access Administrator + Contributor role on the subscription"
        }
        
    }
    catch {
        Write-Verbose $Error[0]
        Write-Error "Correct role not found. Please make sure you have either Owner or User Access Administrator + Contributor role on the subscription"
        exit
    }

    Write-Progress -Activity "Checking script prerequisites" -Status "Checking if resource group exists" -PercentComplete 20 -Id 1 -ErrorAction SilentlyContinue
    # Grab the resource group and store it in a variable
    try {
        $ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    }
    catch {
        Write-Verbose $Error[0]
        Write-Error "Failed to get resource group"
        exit
    }

}

Process {
    Write-Progress -Activity "Setting up prerequisites" -Status "Checking if necessary resource providers are registered" -PercentComplete 25 -Id 1 -ErrorAction SilentlyContinue
    # Step 1: Register necessary resource providers
    # Grab all registered resource providers
    try {
        $RegisteredProviders = Get-AzResourceProvider -ListAvailable -ErrorAction Stop | Where-Object RegistrationState -eq "Registered"
    }
    catch {
        Write-Verbose $Error[0]
        Write-Error "Failed to get registered resource providers"
        exit
    }

    # Check if the necessary resource providers are registered, else register
    try {
        Write-Progress -Activity "Doing resource providers" -Status "Checking Microsoft.DesktopVirtualization" -PercentComplete 15 -Id 2 -ParentId 1 -ErrorAction SilentlyContinue
        # Check for Microsoft.DesktopVirtualization, register if not registered
        if ($RegisteredProviders.ProviderNamespace -notcontains "Microsoft.DesktopVirtualization") {
            try {
                Register-AzResourceProvider -ProviderNamespace "Microsoft.DesktopVirtualization" -ErrorAction Stop
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to register Microsoft.DesktopVirtualization"
            }
        }

        Write-Progress -Activity "Doing resource providers" -Status "Checking Microsoft.VirtualMachineImages" -PercentComplete 30 -Id 2 -ParentId 1 -ErrorAction SilentlyContinue
        # Check for Microsoft.VirtualMachineImages, register if not registered
        if ($RegisteredProviders.ProviderNamespace -notcontains "Microsoft.VirtualMachineImages") {
            try {
                Register-AzResourceProvider -ProviderNamespace "Microsoft.VirtualMachineImages" -ErrorAction Stop
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to register Microsoft.VirtualMachineImages"
            }
        }

        Write-Progress -Activity "Doing resource providers" -Status "Checking Microsoft.Storage" -PercentComplete 45 -Id 2 -ParentId 1 -ErrorAction SilentlyContinue
        # Check for Microsoft.Storage, register if not registered
        if ($RegisteredProviders.ProviderNamespace -notcontains "Microsoft.Storage") {
            try {
                Register-AzResourceProvider -ProviderNamespace "Microsoft.Storage" -ErrorAction Stop
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to register Microsoft.Storage"
            }
        }

        Write-Progress -Activity "Doing resource providers" -Status "Checking Microsoft.Compute" -PercentComplete 60 -Id 2 -ParentId 1 -ErrorAction SilentlyContinue
        # Check for Microsoft.Compute, register if not registered
        if ($RegisteredProviders.ProviderNamespace -notcontains "Microsoft.Compute") {
            try {
                Register-AzResourceProvider -ProviderNamespace "Microsoft.Compute" -ErrorAction Stop
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to register Microsoft.Compute"
            }
        }

        Write-Progress -Activity "Doing resource providers" -Status "Checking Microsoft.Network" -PercentComplete 75 -Id 2 -ParentId 1 -ErrorAction SilentlyContinue
        # Check for Microsoft.Network, register if not registered
        if ($RegisteredProviders.ProviderNamespace -notcontains "Microsoft.Network") {
            try {
                Register-AzResourceProvider -ProviderNamespace "Microsoft.Network" -ErrorAction Stop
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to register Microsoft.Network"
            }
        }

        Write-Progress -Activity "Doing resource providers" -Status "Checking Microsoft.KeyVault" -PercentComplete 90 -Id 2 -ParentId 1 -ErrorAction SilentlyContinue
        # Check for Microsoft.KeyVault, register if not registered
        if ($RegisteredProviders.ProviderNamespace -notcontains "Microsoft.KeyVault") {
            try {
                Register-AzResourceProvider -ProviderNamespace "Microsoft.KeyVault" -ErrorAction Stop
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to register Microsoft.KeyVault"
            }
        }
        Write-Progress -Activity "Doing resource providers" -Status "Checking Microsoft.KeyVault" -Completed -Id 2 -ParentId 1 -ErrorAction SilentlyContinue


    }
    catch {
        Write-Verbose $Error[0]
        Write-Error "Failed to register necessary resource providers"
        exit
    }

    Write-Progress -Activity "Setting up prerequisites" -Status "Creating user-assigned managed identity" -PercentComplete 40 -Id 1 -ErrorAction SilentlyContinue
    # Step 2: Create a user-assigned managed identity
    try {
        $ManagedIdentity = New-AzUserAssignedIdentity -ResourceGroupName $ResourceGroup.ResourceGroupName -Name "CustomImageTemplateIdentity" -Location $ResourceGroup.Location -ErrorAction Stop
    }
    catch {
        Write-Verbose $Error[0]
        Write-Error "Failed to create user-assigned managed identity"
        exit
    }

    Write-Progress -Activity "Setting up prerequisites" -Status "Creating custom role in Azure" -PercentComplete 55 -Id 1 -ErrorAction SilentlyContinue
    # Step 3: Create a custom role in Azure
    # Define the role
    try {
        $role = New-Object -TypeName Microsoft.Azure.Commands.Resources.Models.Authorization.PSRoleDefinition 
        $role.Name = 'CustomImageTemplateRole'
        $role.Description = 'Can do all things required for Custom Image Templates'
        $role.IsCustom = $true
        $role.AssignableScopes = @("/subscriptions/$($Context.subscription)/resourceGroups/$($ResourceGroup.ResourceGroupName)")
        $role.Actions = @(
            "Microsoft.Compute/galleries/read",
            "Microsoft.Compute/galleries/images/read",
            "Microsoft.Compute/galleries/images/versions/read",
            "Microsoft.Compute/galleries/images/versions/write",
            "Microsoft.Compute/images/write",
            "Microsoft.Compute/images/read",
            "Microsoft.Compute/images/delete"
        )
    }
    catch {
        Write-Verbose $Error[0]
        Write-Error "Failed to define custom role"
        exit
    }

    # Create the role
    try {
        $CustomRole = New-AzRoleDefinition -Role $role -ErrorAction Stop
    }
    catch {
        Write-Verbose $Error[0]
        Write-Error "Failed to create custom role"
        exit
    }

    Write-Progress -Activity "Setting up prerequisites" -Status "Assigning the custom role to the managed identity" -PercentComplete 70 -Id 1 -ErrorAction SilentlyContinue
    # Step 4: Assign the custom role to the managed identity
    try {
        Start-Sleep -Seconds 10
        $AssignedRole = New-AzRoleAssignment -ObjectId $ManagedIdentity.PrincipalId -RoleDefinitionName $CustomRole.Name -Scope "/subscriptions/$($Context.subscription)/resourceGroups/$($ResourceGroup.ResourceGroupName)" -ErrorAction Stop
    }
    catch {
        Write-Verbose $Error[0]
        Write-Error "Failed to assign the custom role to the managed identity"
        exit
    }

    Write-Progress -Activity "Setting up prerequisites" -Status "Creating Azure Compute Gallery and VM image definition" -PercentComplete 85 -Id 1 -ErrorAction SilentlyContinue
    # Step 5: Create Azure Compute Gallery with 1 VM image definition
    
    Write-Progress -Activity "Creating gallery and image definition" -Status "Creating Azure Compute Gallery" -PercentComplete 40 -Id 2 -ParentId 1 -ErrorAction SilentlyContinue
    # Create the gallery
    try {
        $Gallery = New-AzGallery -ResourceGroupName $ResourceGroup.ResourceGroupName -Name "CustomImageGallery" -Location $ResourceGroup.Location -Description "Gallery used for Custom Image Templates" -ErrorAction Stop
    }
    catch {
        Write-Verbose $Error[0]
        Write-Error "Failed to create Azure Compute Gallery"
        exit
    }

    Write-Progress -Activity "Creating gallery and image definition" -Status "Creating VM image definition" -PercentComplete 80 -Id 2 -ParentId 1 -ErrorAction SilentlyContinue
    # Create the image definition
    try {
        $ImageDefinition = New-AzGalleryImageDefinition -ResourceGroupName $ResourceGroup.ResourceGroupName -GalleryName "CustomImageGallery" -Name "CustomImageDefinition" -Location $ResourceGroup.Location -Publisher "PetterTech" -Offer "CustomImage" -Sku "01" -OsState Generalized -OsType Windows -HyperVGeneration V2 -ErrorAction Stop
    }
    catch {
        Write-Verbose $Error[0]
        Write-Error "Failed to create image definition"
        exit
    }

}

End {
    Write-Progress -Activity "Setting up prerequisites" -Status "Cleaning up" -PercentComplete 95 -Id 1 -ErrorAction SilentlyContinue
    # Writing out success message
    Write-Host "Prerequisites for Custom Image Templates are set up successfully" -ForegroundColor Green

    # Clear all variables
    Remove-Variable -Name "ResourceGroup" -ErrorAction SilentlyContinue
    Remove-Variable -Name "RegisteredProviders" -ErrorAction SilentlyContinue
    Remove-Variable -Name "ManagedIdentity" -ErrorAction SilentlyContinue
    Remove-Variable -Name "role" -ErrorAction SilentlyContinue
    Remove-Variable -Name "CustomRole" -ErrorAction SilentlyContinue
    Remove-Variable -Name "AssignedRole" -ErrorAction SilentlyContinue
    Remove-Variable -Name "Gallery" -ErrorAction SilentlyContinue
    Remove-Variable -Name "ImageDefinition" -ErrorAction SilentlyContinue
    Remove-Variable -Name "Context" -ErrorAction SilentlyContinue
    Remove-Variable -Name "RoleAssignments" -ErrorAction SilentlyContinue
    Remove-Variable -Name "currentVerbosePreference" -ErrorAction SilentlyContinue
    Remove-Variable -Name "ResourceGroupName" -ErrorAction SilentlyContinue
    Write-Progress -Activity "Setting up prerequisites" -Status "Completed" -Completed -Id 1 -ErrorAction SilentlyContinue
}