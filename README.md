# Github Actions For Architecture Deployment (CI/CD)

This repo is an overview/walkthrough on using GitHub Actions to deploy architecture and applications to Azure.

The end result is a secure Azure App Service that connects to an Azure SQL Database, with secrets from Azure Key Vault. The application is only accessible from a private virtual network and the ingress to that network is a public IP address that routes to an Azure Application Gateway with a Web Application Firewall.

The architecture is deployed using Azure Bicep and the application is deployed using GitHub Actions.

In the end, it is the hope of the authors that you would have enough information to create a solution using bicep and GitHub Actions to deploy your own architecture and applications.

## Prerequisites

You will need the following tools and services to complete this walkthrough:

1) Git [Download here](https://git-scm.com/downloads)
    - [Getting Started with Git](https://docs.github.com/en/get-started/getting-started-with-git/set-up-git)  
1) GitHub Account [Sign up here](https://github.com/signup)
1) Azure Account [Sign up here](https://azure.microsoft.com/en-us/free/)
1) Visual Studio Code [Download here](https://code.visualstudio.com/download) 
1) Azure Bicep Extension for Visual Studio Code [Download here](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep)

## Walk-throughs

The walk-throughs are broken down into the following parts:

1) [Part 0 - Before you begin - Introduction to GitHub Actions](./Part0-BeforeYouBegin.md)  

1) [Part 1 - Creating the architecture deployment](./Part1-CreateArchitectureDeployment.md)  

1) [Part 2 - Creating the application deployment](./Part2-CreateApplicationDeployment.md)  

1) [Part 3 - Creating the GitHub Actions workflow](./Part3-CreateGitHubActionsWorkflow.md)  


## Notes

This solution is for demonstration purposes only. It is not intended for production use, as there are a number of security considerations that should be addressed before going live.  For brevity, those resources and configurations are not included in this walkthrough.

For example, the following resources should be evaluated and considered (at least discussed, not necessarily deployed) for a production deployment:

- Firewall for routing traffic out of the network
- NAT Gateway for routing traffic out of the network
- Network Security Groups for controlling traffic within the network
- Azure Policy for enforcing compliance
- Additional logging and monitoring
- Disaster Recovery and Backup solutions
- Resiliency and High Availability solutions
- Route Tables for controlling traffic within the network

## No Guarantee/Disclaimer

There is no guarantee that this solution will work for you.  It is a demonstration and may require additional configuration or troubleshooting to work in your environment.  It is recommended that you understand the solution and the components before deploying it.

By using this solution, you agree that the author is not responsible for any issues that may arise from the use of this solution, and you agree that you will not hold any contributors responsible for any issues that may arise from the use of this solution, nor will you have any rights to take legal action against any contributors to this solution.
