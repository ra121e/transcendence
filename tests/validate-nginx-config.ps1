# Nginx Configuration Validation Tests
# Tests static file serving functionality and proper HTTP headers and responses
# Requirements: 1.1, 1.2

param(
    [switch]$Verbose
)

Write-Host "🧪 Running Nginx Configuration Validation Tests" -ForegroundColor Cyan
Write-Host ""

$script:Passed = 0
$script:Failed = 0

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Success,
        [string]$ErrorMessage = ""
    )
    
    if ($Success) {
        Write-Host "✅ $TestName" -ForegroundColor Green
        $script:Passed++
    } else {
        Write-Host "❌ $TestName" -ForegroundColor Red
        if ($ErrorMessage -and $Verbose) {
            Write-Host "   Error: $ErrorMessage" -ForegroundColor Yellow
        }
        $script:Failed++
    }
}

function Test-FileExists {
    param([string]$FilePath)
    return Test-Path $FilePath
}

function Test-ConfigurationContent {
    param(
        [string]$FilePath,
        [string]$Pattern,
        [string]$Description
    )
    
    if (-not (Test-Path $FilePath)) {
        return @{ Success = $false; Error = "File $FilePath does not exist" }
    }
    
    try {
        $content = Get-Content $FilePath -Raw
        $success = $content -match $Pattern
        return @{ Success = $success; Error = if (-not $success) { "Pattern '$Pattern' not found in $FilePath" } else { "" } }
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

Write-Host "Validating configuration files..." -ForegroundColor Cyan
Write-Host ""

# Test 1: Nginx configuration file exists
$success = Test-FileExists "nginx.conf"
Write-TestResult -TestName "Nginx configuration file exists" -Success $success -ErrorMessage "nginx.conf not found"

# Test 2: Docker Compose configuration exists
$success = Test-FileExists "docker-compose.yml"
Write-TestResult -TestName "Docker Compose configuration exists" -Success $success -ErrorMessage "docker-compose.yml not found"

# Test 3: Static content directory exists
$success = Test-FileExists "static"
Write-TestResult -TestName "Static content directory exists" -Success $success -ErrorMessage "static/ directory not found"

# Test 4: Index.html exists
$success = Test-FileExists "static/index.html"
Write-TestResult -TestName "Index.html file exists" -Success $success -ErrorMessage "static/index.html not found"

# Test 5: CSS file exists
$success = Test-FileExists "static/style.css"
Write-TestResult -TestName "CSS file exists" -Success $success -ErrorMessage "static/style.css not found"

Write-Host ""
Write-Host "Validating Nginx configuration content..." -ForegroundColor Cyan
Write-Host ""

# Test 6: Nginx listens on port 80
$result = Test-ConfigurationContent -FilePath "nginx.conf" -Pattern "listen\s+80" -Description "Port 80 configuration"
Write-TestResult -TestName "Nginx configured to listen on port 80" -Success $result.Success -ErrorMessage $result.Error

# Test 7: Document root configured
$result = Test-ConfigurationContent -FilePath "nginx.conf" -Pattern "root\s+/usr/share/nginx/html" -Description "Document root configuration"
Write-TestResult -TestName "Document root properly configured" -Success $result.Success -ErrorMessage $result.Error

# Test 8: Index file configured
$result = Test-ConfigurationContent -FilePath "nginx.conf" -Pattern "index\s+index\.html" -Description "Index file configuration"
Write-TestResult -TestName "Index file properly configured" -Success $result.Success -ErrorMessage $result.Error

# Test 9: Security headers configured
$result = Test-ConfigurationContent -FilePath "nginx.conf" -Pattern "add_header\s+X-Frame-Options" -Description "X-Frame-Options header"
Write-TestResult -TestName "X-Frame-Options security header configured" -Success $result.Success -ErrorMessage $result.Error

$result = Test-ConfigurationContent -FilePath "nginx.conf" -Pattern "add_header\s+X-Content-Type-Options" -Description "X-Content-Type-Options header"
Write-TestResult -TestName "X-Content-Type-Options security header configured" -Success $result.Success -ErrorMessage $result.Error

$result = Test-ConfigurationContent -FilePath "nginx.conf" -Pattern "add_header\s+X-XSS-Protection" -Description "X-XSS-Protection header"
Write-TestResult -TestName "X-XSS-Protection security header configured" -Success $result.Success -ErrorMessage $result.Error

# Test 10: Gzip compression configured
$result = Test-ConfigurationContent -FilePath "nginx.conf" -Pattern "gzip\s+on" -Description "Gzip compression"
Write-TestResult -TestName "Gzip compression enabled" -Success $result.Success -ErrorMessage $result.Error

# Test 11: Cache headers for static assets
$result = Test-ConfigurationContent -FilePath "nginx.conf" -Pattern "expires\s+1y" -Description "Cache expiration for static assets"
Write-TestResult -TestName "Cache expiration configured for static assets" -Success $result.Success -ErrorMessage $result.Error

# Test 12: MIME types included
$result = Test-ConfigurationContent -FilePath "nginx.conf" -Pattern "include\s+/etc/nginx/mime\.types" -Description "MIME types inclusion"
Write-TestResult -TestName "MIME types properly included" -Success $result.Success -ErrorMessage $result.Error

Write-Host ""
Write-Host "Validating Docker Compose configuration..." -ForegroundColor Cyan
Write-Host ""

# Test 13: Port mapping configured
$result = Test-ConfigurationContent -FilePath "docker-compose.yml" -Pattern "8080:80" -Description "Port mapping"
Write-TestResult -TestName "Port mapping configured (8080:80)" -Success $result.Success -ErrorMessage $result.Error

# Test 14: Static files volume mounted
$result = Test-ConfigurationContent -FilePath "docker-compose.yml" -Pattern "./static:/usr/share/nginx/html" -Description "Static files volume"
Write-TestResult -TestName "Static files volume properly mounted" -Success $result.Success -ErrorMessage $result.Error

# Test 15: Nginx config volume mounted
$result = Test-ConfigurationContent -FilePath "docker-compose.yml" -Pattern "./nginx\.conf:/etc/nginx/nginx\.conf" -Description "Nginx config volume"
Write-TestResult -TestName "Nginx configuration volume properly mounted" -Success $result.Success -ErrorMessage $result.Error

# Test 16: Health check configured
$result = Test-ConfigurationContent -FilePath "docker-compose.yml" -Pattern "healthcheck:" -Description "Health check"
Write-TestResult -TestName "Health check configured" -Success $result.Success -ErrorMessage $result.Error

Write-Host ""
Write-Host "Validating static content..." -ForegroundColor Cyan
Write-Host ""

# Test 17: HTML structure validation
if (Test-Path "static/index.html") {
    $result = Test-ConfigurationContent -FilePath "static/index.html" -Pattern "<!DOCTYPE html>" -Description "HTML5 doctype"
    Write-TestResult -TestName "HTML5 doctype present" -Success $result.Success -ErrorMessage $result.Error
    
    $result = Test-ConfigurationContent -FilePath "static/index.html" -Pattern "Welcome to Extensible Web App" -Description "Welcome message"
    Write-TestResult -TestName "Welcome message present in HTML" -Success $result.Success -ErrorMessage $result.Error
    
    $result = Test-ConfigurationContent -FilePath "static/index.html" -Pattern 'link.*rel="stylesheet".*href="style\.css"' -Description "CSS link"
    Write-TestResult -TestName "CSS stylesheet properly linked" -Success $result.Success -ErrorMessage $result.Error
}

# Test 18: CSS file validation
if (Test-Path "static/style.css") {
    $cssContent = Get-Content "static/style.css" -Raw
    $success = $cssContent.Length -gt 0
    Write-TestResult -TestName "CSS file contains styling rules" -Success $success -ErrorMessage "CSS file is empty"
}

Write-Host ""
Write-Host "📊 Test Results: $script:Passed passed, $script:Failed failed" -ForegroundColor Cyan

if ($script:Failed -gt 0) {
    Write-Host ""
    Write-Host "❌ Some configuration validations failed" -ForegroundColor Red
    Write-Host "Note: These tests validate configuration files. Run integration tests with Docker to test actual functionality." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host ""
    Write-Host "🎉 All configuration validations passed!" -ForegroundColor Green
    Write-Host "Note: Configuration files are valid. Run integration tests with Docker to test actual functionality." -ForegroundColor Yellow
}