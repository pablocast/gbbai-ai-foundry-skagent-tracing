# <img src="./utils/media/ai_foundry.png" alt="Azure Foundry" style="width:80px;height:30px;"/> Azure AI Foundry Agent with Agentic Retrieval Tool

This directory contains Jupyter notebooks for hands-on exercises with Azure AI Foundry.

## 🔧 Prerequisites

+ [azd](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd), used to deploy all Azure resources and assets used in this sample.
+ [PowerShell Core pwsh](https://github.com/PowerShell/powershell/releases) if using Windows
+ [Python 3.11](https://www.python.org/downloads/release/python-3110/)
+  [An Azure Subscription](https://azure.microsoft.com/free/) with Contributor permissions
+  [Sign in to Azure with Azure CLI](https://learn.microsoft.com/cli/azure/authenticate-azure-cli-interactively)
+  [VS Code](https://code.visualstudio.com/) installed with the [Jupyter notebook extension](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.jupyter) enabled

## Instructions

1. **Python Environment Setup**
   ```bash
   python3.11 -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   pip install -r requirements.txt
   ```

2. **Create the infrastructure**
   ```bash
   # Login to Azure (if not already logged in)
   az login

   # Initialize the project (if running for the first time)
   azd init

   # Deploy infrastructure and application to Azure
   azd up
   ```
   
   After running, an `.env` file will be created with all necessary environment variables

3. **Running the Notebooks**
   - Open the notebook [notebook's folder](1-notebooks/) and execute the notebook

4. **Delete the Resources**
    ```bash
   azd down --purge
   ```
