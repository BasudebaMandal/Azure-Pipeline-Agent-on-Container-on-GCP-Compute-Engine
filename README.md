# Azure-Pipeline-Agent-on-Container-on-GCP-Compute-Engine

# Deploy a Self Hosted Azure Pipeline Agent on a Container

This repository provides an implementation of Self Hosted Azure Pipeline Agent as a container hosted on a GCP Compute Engine Machine.
A configuration file has been introduced to make this piece of code re-usable easily.

# Code and Configurations

config.properties: This properties file would have all the variables that is needed to for installing/deploying the agent.
create-azure-pipeline-agent.sh: This bash script orchestrates the agent deployment. Responsible for deploying the agent and register with Azure DevOps
Dockerfile: This is used to build image and spin container out of it.

# Pre-Requisites

One would need to have a Azure DevOps Organization and Project ready. Agent Pools should be already created which will be used in this script.
One would need to have a GCP project. GCP project should have a service account created.
GCP Project's default compute engine service account should have 'Service Account Key Admin' Role added to it.
User should have a GCP compute engine machine to host the agent container.

# Some of the Key Resources which can be reffered

These types of resources are supported:

* [Azure DevOps](https://docs.microsoft.com/en-us/azure/devops/user-guide/what-is-azure-devops?view=azure-devops)
* [Azure Pipeline Agent](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/agents?view=azure-devops&tabs=browser)
* [GCP Compute Engine](https://cloud.google.com/compute/docs)
* [GCP Service Account](https://cloud.google.com/iam/docs/service-accounts)
* [GCP IAM Roles](https://cloud.google.com/iam/docs/overview)
* [Install Docker](https://docs.docker.com/engine/install/)


# Getting Started

Login to the GCP Compute engine machine and install docker and git. Please follow above link to install docker.
Create a base directory inside root filesystem. ex: /azure-pipeline
Clone this repo from github
Navigate to the directory where bash script and Dockerfile is available.
Configure config.properties as per your environment.
Login to your Azure DevOPs project and create PAT token and have it to be used in the following step.
Run the bash script. Ex:  bash create-azure-pipeline-agent.sh PAT_TOKEN
