# Azure Chaos Studio - demo 1
This folder contains the Bicep files neccesary to create a simple lab environment with 3 load balanced virtual machines. The virtual machines all host a simple website with IIS that simply outputs an Hello World.  
The environment also comes with Azure Chaos Studio set up with the neccesary parts to create two included experiments: 1) a redeployment of one vm and 2) a shutdown of one vm.  

To deploy the environment simply deploy main.bicep to an already created resource group.  
Verify the functionality either by opening up a web browser and point it to http://\<public ip of load balancer> or run the following powershell command:
```     
while ($true) {invoke-restmethod <public ip of load balancer> -TimeoutSec 2 && start-sleep 2}
```

After that, go ahead and try to run the experiments and see if they affect the availability of the website.  
Or, create your own with this environment as a starting point.