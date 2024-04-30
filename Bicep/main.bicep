//Scope
targetScope = 'resourceGroup' // Could also be 'managementGroup', 'subscription' or 'tenant'

//Parameters
param parameterThatIsAString string
param parameterThatisAStringWithDefaultValue string = 'Default Value'
param parameterThatIsANumber int
param parameterThatIsABoolean bool
param parameterThatIsAnObject object
param parameterThatIsAnArray array
param parameterThatIsAnObjectWithProperties object = {
  name: 'lorem ipsum'
  meaning: 42
  subObjects: [
    {
      subName: 'first'
      subMeaning: 24
    }
    {
      subName: 'second'
      subMeaning: 25
    }
  ]
}

@description('This is a parameter with a description to it')
param parameterWithDescription string

@secure()
param parameterWithSecure string

@allowed([
  'value1'
  'value2'
  'value3'
])
param parameterWithAllowedValues string

@minLength(3)
@maxLength(5)
param parameterWithLengthRequirements string

//Variables
var twoStringsTogether = '${parameterThatIsAString}${parameterThatisAStringWithDefaultValue}'
var aStringPlusMoreText = '${parameterThatIsAString} more text'
var aStringButInLowercase = toLower(parameterThatisAStringWithDefaultValue)
var aStringButInUppercase = toUpper(parameterThatisAStringWithDefaultValue)
var aStringButWithTrim = trim(parameterThatisAStringWithDefaultValue)
var aUniqueString = uniqueString('prefix')
var aUniqueStringBasedOnResourceGroup = uniqueString((resourceGroup().id))
var aVariableDefinedByLoop = [for i in range(0,5): {
  name: 'count-${i}'
  value: i
}]

//Resources
resource aStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'storageaccount1'
  location: 'westus'
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource manyStorageAccounts 'Microsoft.Storage/storageAccounts@2023-01-01' = [for i in range(0,parameterThatIsANumber): {
  name: 'storageaccount${i}'
  location: 'westus'
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}]

resource aStorageAccountIfTrue 'Microsoft.Storage/storageAccounts@2023-01-01' = if (parameterThatIsABoolean) {
  name: 'storageaccount20'
  location: 'westus'
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource aStorageAccountIf5 'Microsoft.Storage/storageAccounts@2023-01-01' = if (parameterThatIsANumber == 5) {
  name: 'storageaccount30'
  location: 'westus'
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource aStorageAccountThatAlreadyExistsInSameResourceGroup 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: 'storageaccount'
}

resource aStorageAccountThatAlreadyExistsInDifferentResourceGroup 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: 'storageaccount40'
  scope: resourceGroup('differentResourceGroup')
}

resource childResource 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: aStorageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: [
        {
          allowedOrigins: ['*']
          allowedMethods: ['GET']
          allowedHeaders: ['*']
          exposedHeaders: ['*']
          maxAgeInSeconds: 3600
        }
      ]
    }
  }
}

resource anotherChildResource 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = {
  name: 'storageaccount10/default'
  properties: {
    cors: {
      corsRules: [
        {
          allowedOrigins: ['*']
          allowedMethods: ['GET']
          allowedHeaders: ['*']
          exposedHeaders: ['*']
          maxAgeInSeconds: 3600
        }
      ]
    }
  }
}

//Modules
module aModule 'module.bicep' = {
  name: 'module1'
  params: {
    aParameter: 'lorem ipsum'
  }
}

//Outputs
output output1 string = 'output1'
output output2 string = aStorageAccount.name
output output3 string = aStorageAccount.properties.primaryEndpoints.blob
output output4 string = aModule.outputs.something
output outputIfTrue string = parameterThatIsABoolean ? 'it was true' : 'it was false'
output dynamicOutput array = [for item in parameterThatIsAnArray: {
  firstProperty: item
  secondProperty: 'somethingmore${item}'
}]
