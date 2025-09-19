#!/bin/bash
# This script sets environment variables for local development based on Bicep outputs
# Usage: ./scripts/set-env.sh

# Get outputs from azd env get-values (assumes azd deployment)
echo "Getting environment variables from azd..."

# Create .env file with Bicep outputs
cat > .env << EOF
# Environment variables for graphrag-indexer
# Generated from Bicep deployment outputs

# ---- Required for Azure Document Intelligence and Storage ----
AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT=$(azd env get-values | grep AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT | cut -d'=' -f2 | tr -d '"')
AZURE_STORAGE_ACCOUNT_URL=$(azd env get-values | grep AZURE_STORAGE_ACCOUNT_URL | cut -d'=' -f2 | tr -d '"')
AZURE_STORAGE_ACCOUNT_NAME=$(azd env get-values | grep AZURE_STORAGE_ACCOUNT_NAME | cut -d'=' -f2 | tr -d '"')

# ---- AOAI/LLM/Embedding Model Variables ----
AOAI_API_BASE=$(azd env get-values | grep AOAI_API_BASE | cut -d'=' -f2 | tr -d '"')
AOAI_API_VERSION=$(azd env get-values | grep AOAI_API_VERSION | cut -d'=' -f2 | tr -d '"')
AOAI_LLM_MODEL=$(azd env get-values | grep AOAI_LLM_MODEL | cut -d'=' -f2 | tr -d '"')
AOAI_LLM_DEPLOYMENT=$(azd env get-values | grep AOAI_LLM_DEPLOYMENT | cut -d'=' -f2 | tr -d '"')
AOAI_EMBEDDING_MODEL=$(azd env get-values | grep AOAI_EMBEDDING_MODEL | cut -d'=' -f2 | tr -d '"')
AOAI_EMBEDDING_DEPLOYMENT=$(azd env get-values | grep AOAI_EMBEDDING_DEPLOYMENT | cut -d'=' -f2 | tr -d '"')

# ---- Additional Endpoints ----
PROJECT_ENDPOINT=$(azd env get-values | grep PROJECT_ENDPOINT | cut -d'=' -f2 | tr -d '"')
AZURE_SEARCH_ENDPOINT=$(azd env get-values | grep AZURE_SEARCH_ENDPOINT | cut -d'=' -f2 | tr -d '"')
AZURE_OPENAI_ENDPOINT=$(azd env get-values | grep AZURE_OPENAI_ENDPOINT | cut -d'=' -f2 | tr -d '"')
APPLICATION_INSIGHTS_CONNECTION_STRING=$(azd env get-values | grep APPLICATION_INSIGHTS_CONNECTION_STRING | cut -d'=' -f2 | tr -d '"')

EOF

echo ".env file created successfully with deployment outputs!"
echo "You can now use 'docker-compose up' to test your container locally."