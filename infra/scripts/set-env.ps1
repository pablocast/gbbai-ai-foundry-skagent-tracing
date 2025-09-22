# PowerShell script to set environment variables for local development based on Bicep outputs
# Usage: .\scripts\set-env.ps1

Write-Host "Getting environment variables from azd..."

# Get outputs from azd env get-values
$azdEnvValues = azd env get-values

# Parse function to extract value from azd output
function Get-AzdValue($envValues, $key) {
    $line = $envValues | Where-Object { $_ -match "^$key=" }
    if ($line) {
        return $line.Split('=', 2)[1].Trim('"')
    }
    return ""
}

# Create .env file content
$envContent = @"
# Environment variables for graphrag-indexer
# Generated from Bicep deployment outputs

# ---- Required for Azure Document Intelligence and Storage ----
AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT=$(Get-AzdValue $azdEnvValues "AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT")
AZURE_STORAGE_ACCOUNT_URL=$(Get-AzdValue $azdEnvValues "AZURE_STORAGE_ACCOUNT_URL")
AZURE_STORAGE_ACCOUNT_NAME=$(Get-AzdValue $azdEnvValues "AZURE_STORAGE_ACCOUNT_NAME")

# ---- AOAI/LLM/Embedding Model Variables ----
AOAI_API_BASE=$(Get-AzdValue $azdEnvValues "AOAI_API_BASE")
AOAI_API_VERSION=$(Get-AzdValue $azdEnvValues "AOAI_API_VERSION")
AOAI_LLM_MODEL=$(Get-AzdValue $azdEnvValues "AOAI_LLM_MODEL")
AOAI_LLM_DEPLOYMENT=$(Get-AzdValue $azdEnvValues "AOAI_LLM_DEPLOYMENT")

# ---- Additional Endpoints ----
PROJECT_ENDPOINT=$(Get-AzdValue $azdEnvValues "PROJECT_ENDPOINT")
AZURE_SEARCH_ENDPOINT=$(Get-AzdValue $azdEnvValues "AZURE_SEARCH_ENDPOINT")
AZURE_OPENAI_ENDPOINT=$(Get-AzdValue $azdEnvValues "AZURE_OPENAI_ENDPOINT")
APPLICATION_INSIGHTS_CONNECTION_STRING=$(Get-AzdValue $azdEnvValues "APPLICATION_INSIGHTS_CONNECTION_STRING")
SEMANTICKERNEL_EXPERIMENTAL_GENAI_ENABLE_OTEL_DIAGNOSTICS_SENSITIVE=true
"@

# Write .env file
$envContent | Out-File -FilePath ".env" -Encoding UTF8

Write-Host ".env file created successfully with deployment outputs!"
Write-Host "You can now use 'docker-compose up' to test your container locally."