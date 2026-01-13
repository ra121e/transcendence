# Unit Tests for Nginx Configuration
# Tests static file serving functionality and proper HTTP headers and responses
# Requirements: 1.1, 1.2

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

Write-Host "🧪 Running Nginx Configuration Unit Tests" -ForegroundColor Cyan
Write-Host ""

$script:Passed = 0
$script:Failed = 0
$script:ContainerStarted = $false

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

function Start-TestContainer {
    Write-Host "🐳 Starting Docker container..." -ForegroundColor Yellow
    
    try {
        $result = docker compose up -d 2>&1
        if ($LASTEXITCODE -eq 0) {
            $script:ContainerStarted = $true
            Write-Host "✅ Container started successfully" -ForegroundColor Green
            
            # Wait for container to be ready
            Write-Host "⏳ Waiting for container to be ready..." -ForegroundColor Yellow
            $attempts = 0
            $maxAttempts = 30
            
            do {
                try {
                    $response = Invoke-WebRequest -Uri "http://localhost:8080/" -TimeoutSec 2 -ErrorAction SilentlyContinue
                    if ($response.StatusCode -eq 200) {
                        Write-Host "✅ Container is ready" -ForegroundColor Green
                        return $true
                    }
                } catch {
                    # Ignore errors during startup
                }
                Start-Sleep -Seconds 1
                $attempts++
            } while ($attempts -lt $maxAttempts)
            
            Write-Host "❌ Container failed to start within timeout" -ForegroundColor Red
            return $false
        } else {
            Write-Host "❌ Failed to start container: $result" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Failed to start container: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Stop-TestContainer {
    if ($script:ContainerStarted) {
        Write-Host "🛑 Stopping Docker container..." -ForegroundColor Yellow
        try {
            docker compose down 2>&1 | Out-Null
            Write-Host "✅ Container stopped" -ForegroundColor Green
        } catch {
            Write-Host "⚠️ Warning: Failed to stop container cleanly" -ForegroundColor Yellow
        }
    }
}

function Test-HttpRequest {
    param(
        [string]$Uri,
        [int]$ExpectedStatusCode = 200,
        [string]$ExpectedContentType = $null,
        [string]$ExpectedContent = $null,
        [string]$ExpectedHeader = $null,
        [string]$ExpectedHeaderValue = $null
    )
    
    try {
        $response = Invoke-WebRequest -Uri $Uri -TimeoutSec 10
        
        # Check status code
        if ($response.StatusCode -ne $ExpectedStatusCode) {
            return @{ Success = $false; Error = "Expected status $ExpectedStatusCode, got $($response.StatusCode)" }
        }
        
        # Check content type
        if ($ExpectedContentType) {
            $contentType = $response.Headers["Content-Type"]
            if (-not $contentType -or $contentType -notlike "*$ExpectedContentType*") {
                return @{ Success = $false; Error = "Expected content type '$ExpectedContentType', got '$contentType'" }
            }
        }
        
        # Check content
        if ($ExpectedContent) {
            if ($response.Content -notlike "*$ExpectedContent*") {
                return @{ Success = $false; Error = "Expected content '$ExpectedContent' not found" }
            }
        }
        
        # Check specific header
        if ($ExpectedHeader -and $ExpectedHeaderValue) {
            $headerValue = $response.Headers[$ExpectedHeader]
            if (-not $headerValue -or $headerValue -ne $ExpectedHeaderValue) {
                return @{ Success = $false; Error = "Expected header '${ExpectedHeader}: ${ExpectedHeaderValue}', got '${ExpectedHeader}: ${headerValue}'" }
            }
        }
        
        return @{ Success = $true; Response = $response }
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

# Cleanup function
function Cleanup {
    Stop-TestContainer
}

# Register cleanup
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { Cleanup }

try {
    # Start container
    if (-not (Start-TestContainer)) {
        Write-Host "Failed to start container for testing" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "Running tests..." -ForegroundColor Cyan
    Write-Host ""
    
    # Test 1: Static file serving functionality - index.html
    $result = Test-HttpRequest -Uri "http://localhost:8080/" -ExpectedStatusCode 200 -ExpectedContentType "text/html"
    Write-TestResult -TestName "Should serve index.html from root URL" -Success $result.Success -ErrorMessage $result.Error
    
    # Test 2: HTML content verification
    $result = Test-HttpRequest -Uri "http://localhost:8080/" -ExpectedContent "Welcome to Extensible Web App"
    Write-TestResult -TestName "Should return HTML content with welcome message" -Success $result.Success -ErrorMessage $result.Error
    
    # Test 3: CSS file serving
    $result = Test-HttpRequest -Uri "http://localhost:8080/style.css" -ExpectedStatusCode 200 -ExpectedContentType "text/css"
    Write-TestResult -TestName "Should serve CSS files with correct content type" -Success $result.Success -ErrorMessage $result.Error
    
    # Test 4: Security headers
    $result = Test-HttpRequest -Uri "http://localhost:8080/" -ExpectedHeader "X-Frame-Options" -ExpectedHeaderValue "SAMEORIGIN"
    Write-TestResult -TestName "Should include X-Frame-Options header" -Success $result.Success -ErrorMessage $result.Error
    
    $result = Test-HttpRequest -Uri "http://localhost:8080/" -ExpectedHeader "X-Content-Type-Options" -ExpectedHeaderValue "nosniff"
    Write-TestResult -TestName "Should include X-Content-Type-Options header" -Success $result.Success -ErrorMessage $result.Error
    
    $result = Test-HttpRequest -Uri "http://localhost:8080/" -ExpectedHeader "X-XSS-Protection" -ExpectedHeaderValue "1; mode=block"
    Write-TestResult -TestName "Should include X-XSS-Protection header" -Success $result.Success -ErrorMessage $result.Error
    
    # Test 5: Cache headers for static assets
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/style.css" -TimeoutSec 10
        $cacheControl = $response.Headers["Cache-Control"]
        $success = $cacheControl -and $cacheControl -like "*public*"
        Write-TestResult -TestName "Should set Cache-Control header for CSS files" -Success $success -ErrorMessage "Cache-Control header: $cacheControl"
    } catch {
        Write-TestResult -TestName "Should set Cache-Control header for CSS files" -Success $false -ErrorMessage $_.Exception.Message
    }
    
    # Test 6: 404 handling
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/nonexistent.html" -ErrorAction SilentlyContinue
        $success = $false  # Should not reach here
        Write-TestResult -TestName "Should return 404 for non-existent files" -Success $success -ErrorMessage "Expected 404, got $($response.StatusCode)"
    } catch {
        $success = $_.Exception.Response.StatusCode -eq 404
        Write-TestResult -TestName "Should return 404 for non-existent files" -Success $success -ErrorMessage $_.Exception.Message
    }
    
    # Test 7: Server identification
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/" -TimeoutSec 10
        $server = $response.Headers["Server"]
        $success = $server -and $server -like "*nginx*"
        Write-TestResult -TestName "Should identify as nginx server" -Success $success -ErrorMessage "Server header: $server"
    } catch {
        Write-TestResult -TestName "Should identify as nginx server" -Success $false -ErrorMessage $_.Exception.Message
    }
    
    Write-Host ""
    Write-Host "📊 Test Results: $script:Passed passed, $script:Failed failed" -ForegroundColor Cyan
    
    if ($script:Failed -gt 0) {
        Write-Host ""
        Write-Host "❌ Some tests failed" -ForegroundColor Red
        exit 1
    } else {
        Write-Host ""
        Write-Host "🎉 All tests passed!" -ForegroundColor Green
    }
    
} finally {
    Cleanup
}