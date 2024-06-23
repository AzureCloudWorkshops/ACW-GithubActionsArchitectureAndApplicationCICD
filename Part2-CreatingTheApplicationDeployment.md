# Part 2 - Creating the Application Deployment

In this part, you will create the application deployment. 

## Table of Contents

- [Table of Contents](#table-of-contents)
    - [Step 1: Create the Deployment](#step-1-create-the-deployment)
    - [Step 2: Make it private](#step-2-make-it-private)

## Step 1: Create the Deployment

In the past you could just create a deployment from the portal. With recent changes, you can no longer do that without changing the setting to allow for publishing via the publish profile. 

For this reason, it's recommended to use the Azure Login and Deployment actions instead of referencing the publish profile.

1. Ensure that you have the app code in your repository.

    You will need to have a repository (this one or another one) that contains the code for the application you want to deploy. The workshop repository contains the code for the sample application.

1. With the application code in the `app` or `src` folder, you can now create the deployment.

    You can either create a new file to allow the independent deployment of the application or add the deployment to the existing workflow file after the completion of the infrastructure deployment.  The option you choose will depend on your needs. However, it is likely that you will want to deploy the application after the infrastructure is deployed and you will do this independently after the architecture is created, so you will likely want to run the deployment as a separate workflow.

    You can still leverage the same environments and secrets that you created in the previous part.

    - Create a new file in the `.github/workflows` folder called `deploy-app.yml`.

    name: Deploy ASP.NET Core app to Azure Web App - 2024 edition

    ```yaml
    name: Deploy ASP.NET Core app to Azure Web App - 2024 edition

    on:
    push:
        branches:
        - main
    workflow_dispatch:

    permissions:
        id-token: write
        contents: read

    env:
    DOTNET_VERSION: '6.x'
    AZURE_TENANT_ID:  ${{ secrets.AZURE_TENANT_ID }}

    jobs:
      build-and-deploy:
        runs-on: ubuntu-latest
        environment:
        name: 'dev'
        defaults:
        run:
            working-directory: ./app
            
        steps:
        - uses: actions/checkout@v4

        - name: Set up .NET Core
            uses: actions/setup-dotnet@v4
            with:
            dotnet-version: ${{ env.DOTNET_VERSION }}

        - name: Build with dotnet
            run: dotnet build --configuration Release

        - name: dotnet publish
            run: dotnet publish -c Release -o ${{env.DOTNET_ROOT}}/myapp

        - name: Login to Azure
            uses: azure/login@v2
            with:
            client-id: ${{ vars.AZURE_CLIENT_ID }}
            tenant-id: ${{ env.AZURE_TENANT_ID }}
            subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
    
        - name: Deploy to Azure Web App
            id: deploy-to-webapp
            uses: azure/webapps-deploy@v2
            with:
            app-name: ${{ vars.APP_NAME }}
            slot-name: ${{ vars.SLOT_NAME }}
            package: ${{ env.DOTNET_ROOT }}/myapp
    ```  

    >**Note:** For more information on deploying to Azure from GitHub, [see this workshop](https://github.com/AzureCloudWorkshops/ACW_DeployAppServiceToAzureViaGitHubActions)  

1. Add an environment variable to each environment for the app name and slot name.

    - Go to the repository settings.
    - Click on the `Environments` tab.
    - Click on the `dev` button.
    - Add the `APP_NAME` and `SLOT_NAME` environment variables.

    ```text
    APP_NAME: <whateveryourappnameis> [i.e. ContactWeb-20291231acw]
    SLOT_NAME: Production
    ```

    >**Note:** In the real-world you'd likely make a slot and deploy to the slot.  For simplicity, we are deploying to the production slot in this walkthrough.

1. Commit the changes to the repository.

    Commit the changes and push to the repository. This will trigger the workflow to run.

1. Browse to the website
    
    Provided everything is set correctly, the site should be working against the database.

## Step 2: Make it private

The app is currently set to be public because the next steps would be to make a WAG, set the application to disable public endpoints, and only come in through the WAG.  However, this walkthrough will not cover these steps.  Here are the things you would need to do in order to secure the website completely behind a WAG/WAF.

1. Set the website to default to `disabled` public endpoints.
1. Get your SSL from your provider of choice into Azure Key Vault certificates
1. Create a public ip address for the WAG.
1. Add a subnet for the WebApplicationGateway (WAG).
1. Create a WAG and set the SSL to the keyvault (use the managed identity built with the IaC that is already in place). Put the WAG in the subnet.  Create the WAF policy with bot rules, OWASP, and any other rules you want to apply (like only allowing certain countries).
1. Make your target the app service which should be able to resolve via the private endpoint already in place.
1. Modify the deployment to use a private storage or container for the zip because the publish will no longer work withouth the public endpoint (may require creating a permanent storage account for the zip file that just uses temp containers).
    - https://azure.github.io/AppService/2021/03/01/deploying-to-network-secured-sites-2.html
    or
    - https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-script-vnet-private-endpoint?WT.mc_id=MVP_323261  
