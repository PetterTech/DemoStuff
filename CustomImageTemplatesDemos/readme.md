# Custom Image Templates Demos
This folder contains a powershell script for setting up the prerequisites for custom image templates.  
It also contains a Bicep template for setting up the AVD environment as I did in the video.  
This is all intended to be used in conjunction with my video on custom image templates. You can find the video [here](https://youtu.be/o3A9J7CbCyA/).

## How to use powershell script to set up the prerequisites
1. Clone or download this repository to your local machine.
2. Navigate to the `CustomImageTemplatesDemos` folder.
3. Connect to your Azure subscription using the `Connect-AzAccount` cmdlet.
4. Create a new resource group using the `New-AzResourceGroup` cmdlet.
5. Run the `prereqs.ps1` script file.
6. Follow the rest of the steps in my video and have fun testing out custom image templates!

## How to use the Bicep template to set up the AVD environment
Given that you've followed the steps above, you can now use the Bicep template to set up the AVD environment.  
Simply run the following command in the `CustomImageTemplatesDemos` folder:
```powershell
new-AzResourceGroupDeployment -ResourceGroupName <resource-group-name> -TemplateFile .\CITDemo.bicep -groupID <id of your Entra ID group>
```