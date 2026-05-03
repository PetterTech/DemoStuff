import radius as radius from 'br:ghcr.io/radius-project/rad-bicep-types:latest'

@description('Radius environment to deploy into. Passed automatically by "rad deploy --environment".')
param environment string

resource app 'Applications.Core/applications@2023-10-01-preview' = {
  name: 'demo'
  properties: {
    environment: environment
  }
}

resource container 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'demo-container'
  properties: {
    application: app.id
    container: {
      image: 'nginx:latest'
      ports: {
        web: { containerPort: 80 }
      }
    }
    connections: {}
  }
}
