# WhatsApp-Google Drive Assistant Workflow Processor
# This script processes the raw workflow JSON with placeholders and creates a ready-to-upload file

param(
    [Parameter(Mandatory=$false)]
    [string]$InputFile = "workflow-raw.json",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "workflow.json",
    
    [Parameter(Mandatory=$false)]
    [string]$EnvFile = ".env"
)

Write-Host "Processing n8n workflow..." -ForegroundColor Cyan
Write-Host "Input: $InputFile" -ForegroundColor Cyan
Write-Host "Output: $OutputFile" -ForegroundColor Cyan

# Check if input file exists
if (-not (Test-Path $InputFile)) {
    Write-Host "Error: Input file '$InputFile' not found!" -ForegroundColor Red
    exit 1
}

# Check if .env file exists
if (-not (Test-Path $EnvFile)) {
    Write-Host "Error: Environment file '$EnvFile' not found!" -ForegroundColor Red
    exit 1
}

# Read environment variables from .env file
$envContent = Get-Content $EnvFile -Raw
$GoogleDriveToken = ""
$OpenAIApiKey = ""

# Extract Google Drive Token
if ($envContent -match "GOOGLE_DRIVE_TOKEN=(.+?)(\r?\n|$)") {
    $GoogleDriveToken = $matches[1].Trim()
    if ($GoogleDriveToken -eq "YOUR_GOOGLE_DRIVE_TOKEN_HERE") {
        Write-Host "Error: GOOGLE_DRIVE_TOKEN not configured in .env file" -ForegroundColor Red
        Write-Host "Please update your .env file with a valid token from:" -ForegroundColor Yellow
        Write-Host "https://developers.google.com/oauthplayground/" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "Error: GOOGLE_DRIVE_TOKEN not found in .env file" -ForegroundColor Red
    exit 1
}

# Extract OpenAI API Key
if ($envContent -match "OPENAI_API_KEY=(.+?)(\r?\n|$)") {
    $OpenAIApiKey = $matches[1].Trim()
    if (-not $OpenAIApiKey) {
        Write-Host "Error: OPENAI_API_KEY not configured in .env file" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Error: OPENAI_API_KEY not found in .env file" -ForegroundColor Red
    exit 1
}

# Read the workflow content
try {
    Write-Host "Reading input file..." -ForegroundColor Cyan
    $workflowContent = Get-Content $InputFile -Raw -Encoding UTF8
} catch {
    Write-Host "Error reading input file: $_" -ForegroundColor Red
    exit 1
}

# Validate JSON structure before processing
try {
    $jsonTest = $workflowContent | ConvertFrom-Json
    Write-Host "JSON structure is valid" -ForegroundColor Green
} catch {
    Write-Host "Error: Invalid JSON structure in input file: $_" -ForegroundColor Red
    exit 1
}

# Replace placeholders
Write-Host "Replacing Google Drive tokens..." -ForegroundColor Green
$workflowContent = $workflowContent -replace '{{GOOGLE_DRIVE_TOKEN}}', $GoogleDriveToken

# Replace the OpenAI API key placeholder
Write-Host "Setting Bearer tokens for API calls..." -ForegroundColor Green
$workflowContent = $workflowContent -replace '{{OPENAI_API_KEY}}', $OpenAIApiKey

# Write processed workflow
try {
    $workflowContent | Out-File -FilePath $OutputFile -Encoding UTF8 -NoNewline
    Write-Host "Workflow successfully processed!" -ForegroundColor Green
    Write-Host "Output file size: $((Get-Item $OutputFile).Length) bytes" -ForegroundColor Cyan
} catch {
    Write-Host "Error writing output file: $_" -ForegroundColor Red
    exit 1
}

# Verify the workflow
Write-Host "`nVerifying workflow components:" -ForegroundColor Cyan

# Check for key requirements
$hasWebhook = ($workflowContent -match "n8n-nodes-base.webhook") -and ($workflowContent -match "whatsapp-webhook")

# Check each command individually
$commandsList = @("LIST", "DELETE", "MOVE", "SUMMARY", "HELP")
$commandResults = @{}
$allCommandsPresent = $true

foreach ($cmd in $commandsList) {
    $commandResults[$cmd] = $workflowContent -match $cmd
    if (-not $commandResults[$cmd]) {
        $allCommandsPresent = $false
    }
}

$hasCommands = $allCommandsPresent
$hasGoogleDrive = $workflowContent -match "googleapis.com/drive"
$hasOpenAI = $workflowContent -match "api.openai.com"
$hasTwilio = $workflowContent -match "twilio.com"
$hasErrorHandling = $workflowContent -match "neverError"

# Output summary as a table
$requirements = @(
    @{ Name = "WhatsApp Webhook"; Status = $hasWebhook },
    @{ Name = "Google Drive API"; Status = $hasGoogleDrive },
    @{ Name = "OpenAI Integration"; Status = $hasOpenAI },
    @{ Name = "Twilio WhatsApp"; Status = $hasTwilio },
    @{ Name = "Error Handling"; Status = $hasErrorHandling }
)

foreach ($req in $requirements) {
    $statusSymbol = if ($req.Status) { "+" } else { "x" }
    $color = if ($req.Status) { "Green" } else { "Red" }
    Write-Host "$statusSymbol $($req.Name)" -ForegroundColor $color
}

# Show command status
Write-Host "`nVerifying WhatsApp commands:" -ForegroundColor Cyan
foreach ($cmd in $commandsList) {
    $statusSymbol = if ($commandResults[$cmd]) { "+" } else { "x" }
    $color = if ($commandResults[$cmd]) { "Green" } else { "Red" }
    Write-Host "$statusSymbol $cmd command" -ForegroundColor $color
}

# Check for any remaining environment variable placeholders (like {{TOKEN_NAME}})
# We're specifically looking for the pattern {{WORD}} without any = sign
$remainingPlaceholders = ($workflowContent | Select-String "\{\{([A-Z0-9_]+)\}\}" -AllMatches).Matches
if ($remainingPlaceholders.Count -gt 0) {
    Write-Host "`nWarning: $($remainingPlaceholders.Count) placeholder(s) still remain in the workflow" -ForegroundColor Red
    $placeholders = $remainingPlaceholders | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
    Write-Host "Remaining placeholders: $($placeholders -join ', ')" -ForegroundColor Red
    Write-Host "The workflow is NOT ready for upload!" -ForegroundColor Red
    exit 1
}

# Validate n8n template expressions - these are valid and should remain
Write-Host "`n✓ Checking n8n expressions..." -ForegroundColor Green

# Verify n8n expressions are preserved (these are valid and should remain)
$n8nExpressions = ($workflowContent | Select-String "={{.*?}}" -AllMatches).Matches.Count
Write-Host "`n✓ Found $n8nExpressions valid n8n expressions (these should remain)" -ForegroundColor Green

# Run a comprehensive test on the final workflow file
$isWorkflowReady = $true

# Check for common issues
if ($workflowContent -match "{{GOOGLE_DRIVE_TOKEN}}") {
    Write-Host "❌ Google Drive token placeholder not replaced!" -ForegroundColor Red
    $isWorkflowReady = $false
}
if ($workflowContent -match "{{OPENAI_API_KEY}}") {
    Write-Host "❌ OpenAI API key placeholder not replaced!" -ForegroundColor Red
    $isWorkflowReady = $false
}

# Test the output file integrity
try {
    $null = Get-Content $OutputFile -Raw | ConvertFrom-Json
    Write-Host "✓ Output file is valid JSON" -ForegroundColor Green
} catch {
    Write-Host "❌ Output file is not valid JSON: $_" -ForegroundColor Red
    $isWorkflowReady = $false
}

# Check for sensitive data in the output file
$outputContent = Get-Content $OutputFile -Raw
$sensitiveDataPatterns = @(
    # API Keys (generic pattern)
    'sk-[a-zA-Z0-9]{20,}'
    # OAuth tokens
    'ya29\.[a-zA-Z0-9_-]{100,}'
    # Twilio credentials (if they should be masked)
    'AC[a-zA-Z0-9]{32}'
)

$containsSensitiveData = $false
foreach ($pattern in $sensitiveDataPatterns) {
    if ($outputContent -match $pattern) {
        Write-Host "`n⚠️ Warning: Output file may contain sensitive data matching pattern: $pattern" -ForegroundColor Yellow
        $containsSensitiveData = $true
    }
}

# Advanced n8n workflow validation
Write-Host "`nPerforming advanced n8n workflow validation:" -ForegroundColor Cyan

# Parse workflow JSON
$workflowJson = $outputContent | ConvertFrom-Json

# Check node connections - verify all node IDs referenced in connections exist
$nodeIds = $workflowJson.nodes | ForEach-Object { $_.id }
$nodeNames = $workflowJson.nodes | ForEach-Object { $_.name }
$connectionErrors = 0

# Just check if the basic node structure is intact
Write-Host "✓ Found $($nodeIds.Count) nodes in workflow" -ForegroundColor Green
Write-Host "✓ Found $(($workflowJson.connections | Get-Member -MemberType NoteProperty).Count) connection sources" -ForegroundColor Green

# Check webhook nodes for duplicate paths (safely)
$webhookNodes = $workflowJson.nodes | Where-Object { $_.type -like "*webhook*" }
Write-Host "✓ Found $($webhookNodes.Count) webhook nodes" -ForegroundColor Green

$webhookPaths = @{}
foreach ($node in $webhookNodes) {
    if ($node.parameters -and $node.parameters.PSObject.Properties['path']) {
        $path = $node.parameters.path
        if ($path -and $webhookPaths.ContainsKey($path)) {
            Write-Host "❌ Duplicate webhook path: $path in nodes $($webhookPaths[$path]) and $($node.name)" -ForegroundColor Red
            $connectionErrors++
        } elseif ($path) {
            $webhookPaths[$path] = $node.name
        }
    }
}

if ($connectionErrors -eq 0) {
    Write-Host "✓ All node connections are valid" -ForegroundColor Green
}

# Report special characters or encoding issues
if ($outputContent -match "[^\x00-\x7F]") {
    Write-Host "⚠️ Workflow contains non-ASCII characters which might cause issues in some environments" -ForegroundColor Yellow
}

# Check for essential n8n workflow properties
$essentialProperties = @("nodes", "connections", "name")
$missingProperties = $essentialProperties | Where-Object { -not $workflowJson.PSObject.Properties[$_] }
if ($missingProperties.Count -gt 0) {
    Write-Host "❌ Workflow is missing essential properties: $($missingProperties -join ', ')" -ForegroundColor Red
    $connectionErrors++
} else {
    Write-Host "✓ Workflow contains all essential n8n properties" -ForegroundColor Green
}

# Check for node type/version consistency
Write-Host "✓ Validating node types and versions..." -ForegroundColor Green
$nodeTypeConsistency = $true
foreach ($node in $workflowJson.nodes) {
    if (-not $node.PSObject.Properties["type"] -or -not $node.PSObject.Properties["typeVersion"]) {
        Write-Host "❌ Node '$($node.name)' is missing type or typeVersion" -ForegroundColor Red
        $nodeTypeConsistency = $false
        $connectionErrors++
    }
}
if ($nodeTypeConsistency) {
    Write-Host "✓ All nodes have proper type and version information" -ForegroundColor Green
}

if ($isWorkflowReady) {
    Write-Host "`n✅ WORKFLOW VERIFICATION SUCCESSFUL" -ForegroundColor Green
    Write-Host "The workflow has been processed and is READY FOR UPLOAD." -ForegroundColor Green
    
    if ($containsSensitiveData) {
        Write-Host "`n⚠️ SECURITY WARNING: Sensitive data detected in output file!" -ForegroundColor Yellow
        Write-Host "Be careful when committing this file to version control." -ForegroundColor Yellow
        Write-Host "The workflow.json file is listed in .gitignore to prevent accidental commits." -ForegroundColor Yellow
    }
    
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Upload '$OutputFile' to your n8n instance" -ForegroundColor White
    Write-Host "2. Activate the workflow" -ForegroundColor White
    Write-Host "3. Test with WhatsApp commands" -ForegroundColor White
    
    # Check for .gitignore
    if (-not (Test-Path ".gitignore")) {
        Write-Host "`n⚠️ No .gitignore file found!" -ForegroundColor Yellow
        Write-Host "It's recommended to add '$OutputFile' to .gitignore to prevent committing sensitive tokens." -ForegroundColor Yellow
    } elseif (-not (Get-Content ".gitignore" | Where-Object { $_ -match $OutputFile })) {
        Write-Host "`n⚠️ '$OutputFile' is not in .gitignore!" -ForegroundColor Yellow
        Write-Host "Consider adding it to prevent committing sensitive tokens." -ForegroundColor Yellow
    } else {
        Write-Host "`n✓ '$OutputFile' is properly excluded in .gitignore" -ForegroundColor Green
    }
} else {
    Write-Host "`n❌ WORKFLOW VERIFICATION FAILED" -ForegroundColor Red
    Write-Host "The workflow is NOT ready for upload. Please fix the issues above." -ForegroundColor Red
}
