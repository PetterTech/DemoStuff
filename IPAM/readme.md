# IPAM lab environment
The Bicep file in this folder will setup a (very) simple lab environment for testing the new IPAM feature of Azure Virtual Network Manager.  
It will deploy the following resources:
* Virtual Network Manager (vnm-demoManager)
* Address Pool (ipamPool)
* Static CIDR block (OnPremCIDR)
* vNet (vnet-testnet1)

Currently, you will probably get some warnings when deploying this as the Bicep tools are not updated to include this new IPAM feature yet. But it works, have faith young padawan 👌

Deploy the template to a resource group by running the following command:
```powershell
New-azResourceGroupDeployment -name IPAMDeployement -resourcegroupname <resourcegroupname> -templatefile .\main.bicep
```