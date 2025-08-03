# Task2 - WhatsApp Google Drive Assistant Setup
Write-Host "🚀 Setting up Task2 - WhatsApp Google Drive Assistant..." -ForegroundColor Cyan

# Check prerequisites
Write-Host "📋 Checking prerequisites..." -ForegroundColor Yellow

# Check Docker
try {
    docker --version | Out-Null
    Write-Host "✅ Docker found" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker not found. Please install Docker Desktop first." -ForegroundColor Red
    Write-Host "Download from: https://www.docker.com/products/docker-desktop" -ForegroundColor Blue
    exit 1
}

# Check Node.js
try {
    node --version | Out-Null
    Write-Host "✅ Node.js found" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js not found. Please install Node.js first." -ForegroundColor Red
    Write-Host "Download from: https://nodejs.org/" -ForegroundColor Blue
    exit 1
}

# Start Docker services
Write-Host "🐳 Starting Docker services..." -ForegroundColor Yellow
docker-compose down --remove-orphans
docker-compose up -d

# Wait for services to be ready
Write-Host "⏳ Waiting for services to start..." -ForegroundColor Yellow
Start-Sleep 30

# Check if n8n is ready
$maxAttempts = 12
$attempt = 0
do {
    $attempt++
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5678" -TimeoutSec 5 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ n8n is ready!" -ForegroundColor Green
            break
        }
    } catch {
        Write-Host "⏳ Waiting for n8n... (attempt $attempt/$maxAttempts)" -ForegroundColor Yellow
        Start-Sleep 5
    }
} while ($attempt -lt $maxAttempts)

if ($attempt -eq $maxAttempts) {
    Write-Host "❌ n8n failed to start. Check Docker logs." -ForegroundColor Red
    exit 1
}

# Install localtunnel if not present
try {
    npx localtunnel --version | Out-Null
} catch {
    Write-Host "📦 Installing localtunnel..." -ForegroundColor Yellow
    npm install -g localtunnel
}

# Start tunnel in background
Write-Host "🌐 Starting public tunnel..." -ForegroundColor Yellow
$tunnelJob = Start-Job -ScriptBlock {
    npx localtunnel --port 5678 --subdomain task2-whatsapp-demo
}

# Wait for tunnel to establish
Start-Sleep 10

# Get tunnel URL
$tunnelUrl = "https://task2-whatsapp-demo.loca.lt"
Write-Host "🔗 Tunnel URL: $tunnelUrl" -ForegroundColor Green

# Test webhook connectivity
Write-Host "🧪 Testing webhook connectivity..." -ForegroundColor Yellow
Start-Sleep 5
try {
    $testResponse = Invoke-WebRequest -Uri "$tunnelUrl/webhook-test/webhook" -Method POST -Body "From=whatsapp%3A%2B1234567890&Body=HELP" -ContentType "application/x-www-form-urlencoded" -TimeoutSec 10
    if ($testResponse.StatusCode -eq 200) {
        Write-Host "✅ Webhook is working!" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  Webhook test failed - ensure workflow is imported and active in n8n" -ForegroundColor Yellow
    Write-Host "   Manual steps: Go to http://localhost:5678 → Import workflow.json → Activate workflow" -ForegroundColor Cyan
}

Write-Host "`n🎉 Setup Complete!" -ForegroundColor Green
Write-Host "� WhatsApp Webhook URL: $tunnelUrl/webhook-test/webhook" -ForegroundColor Cyan
Write-Host "🌐 n8n Interface: http://localhost:5678" -ForegroundColor Cyan
Write-Host "⚙️  Configure Twilio webhook with the URL above" -ForegroundColor Yellow

Write-Host "`n🧪 Run test.ps1 to validate setup" -ForegroundColor Blue
