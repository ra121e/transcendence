# Deployment Tests for Single-Command Deployment
# Tests docker-compose up functionality and container startup/shutdown procedures
# Requirements: 2.2

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

Write-Host "🧪 Running Single-Command Deployment Tests" -ForegroundColor Cyan
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

function Test-DockerComposeUp {
    Write-Host "🐳 Testing docker-compose up command..." -ForegroundColor Blue
    Write-Host ""
    
    # Ensure we start clean
    try {
        docker compose down 2>&1 | Out-Null
    } catch {
        # Ignore errors if nothing to stop
    }
    
    # Test 1: docker-compose up command executes without errors
    Write-Host "⏳ docker-compose up command executes successfully... " -NoNewline
    try {
        $result = docker compose up -d 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ PASSED" -ForegroundColor Green
            $script:Passed++
            $script:ContainerStarted = $true
        } else {
            Write-Host "❌ FAILED" -ForegroundColor Red
            if ($Verbose) {
                Write-Host "   Error: $result" -ForegroundColor Yellow
            }
            $script:Failed++
            return $false
        }
    } catch {
        Write-Host "❌ FAILED" -ForegroundColor Red
        if ($Verbose) {
            Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        $script:Failed++
        return $false
    }
    
    # Test 2: Container is created and running
    try {
        $containers = docker ps --filter 'name=extensible-web-app' --filter 'status=running' 2>&1
        $success = $containers -match 'extensible-web-app'
        Write-TestResult -TestName "Container is created and running" -Success $success -ErrorMessage "Container list: $containers"
    } catch {
        Write-TestResult -TestName "Container is created and running" -Success $false -ErrorMessage $_.Exception.Message
    }
    
    # Test 3: Container port mapping is correct
    try {
        $containers = docker ps --filter 'name=extensible-web-app' 2>&1
        $success = $containers -match '8080->80/tcp'
        Write-TestResult -TestName "Port mapping is configured correctly (8080:80)" -Success $success -ErrorMessage "Container info: $containers"
    } catch {
        Write-TestResult -TestName "Port mapping is configured correctly (8080:80)" -Success $false -ErrorMessage $_.Exception.Message
    }
    
    # Test 4: Container health check passes
    Write-Host "⏳ Container health check passes... " -NoNewline
    $attempts = 0
    $maxAttempts = 60  # Wait up to 60 seconds for health check
    $healthStatus = ""
    
    while ($attempts -lt $maxAttempts) {
        try {
            $healthStatus = docker inspect extensible-web-app --format='{{.State.Health.Status}}' 2>&1
            if ($healthStatus -eq "healthy") {
                Write-Host "✅ PASSED" -ForegroundColor Green
                $script:Passed++
                break
            } elseif ($healthStatus -eq "unhealthy") {
                Write-Host "❌ FAILED (unhealthy)" -ForegroundColor Red
                $script:Failed++
                break
            }
        } catch {
            # Continue waiting
        }
        Start-Sleep -Seconds 1
        $attempts++
    }
    
    if ($attempts -eq $maxAttempts -and $healthStatus -ne "healthy") {
        Write-Host "❌ FAILED (timeout waiting for health check)" -ForegroundColor Red
        if ($Verbose) {
            Write-Host "   Last health status: $healthStatus" -ForegroundColor Yellow
        }
        $script:Failed++
    }
    
    # Test 5: Service is accessible on localhost:8080
    Write-Host "⏳ Service is accessible on localhost:8080... " -NoNewline
    $webAttempts = 0
    $webMaxAttempts = 30
    $accessible = $false
    
    while ($webAttempts -lt $webMaxAttempts) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8080/" -TimeoutSec 2 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                Write-Host "✅ PASSED" -ForegroundColor Green
                $script:Passed++
                $accessible = $true
                break
            }
        } catch {
            # Continue waiting
        }
        Start-Sleep -Seconds 1
        $webAttempts++
    }
    
    if (-not $accessible) {
        Write-Host "❌ FAILED (service not accessible)" -ForegroundColor Red
        $script:Failed++
    }
    
    return $true
}

function Test-StartupProcedures {
    Write-Host ""
    Write-Host "🚀 Testing container startup procedures..." -ForegroundColor Blue
    Write-Host ""
    
    # Test 1: Container starts within reasonable time (already started, so this is informational)
    Write-TestResult -TestName "Container starts within reasonable time" -Success $script:ContainerStarted
    
    # Test 2: Container logs show successful startup
    try {
        $logs = docker logs extensible-web-app 2>&1
        $success = $logs -match "(start|ready|listening)"
        Write-TestResult -TestName "Container logs show successful startup" -Success $success -ErrorMessage "Logs: $($logs -join '; ')"
    } catch {
        Write-TestResult -TestName "Container logs show successful startup" -Success $false -ErrorMessage $_.Exception.Message
    }
    
    # Test 3: All required volumes are mounted
    try {
        $inspect = docker inspect extensible-web-app 2>&1 | ConvertFrom-Json
        $success = ($inspect.Mounts | Where-Object { $_.Destination -eq "/usr/share/nginx/html" }) -ne $null
        Write-TestResult -TestName "Static files volume is mounted correctly" -Success $success
    } catch {
        Write-TestResult -TestName "Static files volume is mounted correctly" -Success $false -ErrorMessage $_.Exception.Message
    }
    
    try {
        $inspect = docker inspect extensible-web-app 2>&1 | ConvertFrom-Json
        $success = ($inspect.Mounts | Where-Object { $_.Destination -eq "/etc/nginx/nginx.conf" }) -ne $null
        Write-TestResult -TestName "Nginx config volume is mounted correctly" -Success $success
    } catch {
        Write-TestResult -TestName "Nginx config volume is mounted correctly" -Success $false -ErrorMessage $_.Exception.Message
    }
    
    # Test 4: Container restart policy is configured
    try {
        $restartPolicy = docker inspect extensible-web-app --format='{{.HostConfig.RestartPolicy.Name}}' 2>&1
        $success = $restartPolicy -eq "unless-stopped"
        Write-TestResult -TestName "Container restart policy is set to 'unless-stopped'" -Success $success -ErrorMessage "Restart policy: $restartPolicy"
    } catch {
        Write-TestResult -TestName "Container restart policy is set to 'unless-stopped'" -Success $false -ErrorMessage $_.Exception.Message
    }
}

function Test-ShutdownProcedures {
    Write-Host ""
    Write-Host "🛑 Testing container shutdown procedures..." -ForegroundColor Blue
    Write-Host ""
    
    # Test 1: docker-compose down command executes successfully
    Write-Host "⏳ docker-compose down command executes successfully... " -NoNewline
    try {
        $result = docker compose down 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ PASSED" -ForegroundColor Green
            $script:Passed++
            $script:ContainerStarted = $false
        } else {
            Write-Host "❌ FAILED" -ForegroundColor Red
            if ($Verbose) {
                Write-Host "   Error: $result" -ForegroundColor Yellow
            }
            $script:Failed++
            return $false
        }
    } catch {
        Write-Host "❌ FAILED" -ForegroundColor Red
        if ($Verbose) {
            Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        $script:Failed++
        return $false
    }
    
    # Test 2: Container is stopped and removed
    Write-Host "⏳ Container is stopped and removed... " -NoNewline
    $attempts = 0
    $maxAttempts = 30
    $containerRemoved = $false
    
    while ($attempts -lt $maxAttempts) {
        try {
            $containers = docker ps -a --filter 'name=extensible-web-app' 2>&1
            if (-not ($containers -match 'extensible-web-app')) {
                Write-Host "✅ PASSED" -ForegroundColor Green
                $script:Passed++
                $containerRemoved = $true
                break
            }
        } catch {
            # Continue waiting
        }
        Start-Sleep -Seconds 1
        $attempts++
    }
    
    if (-not $containerRemoved) {
        Write-Host "❌ FAILED (container still exists)" -ForegroundColor Red
        $script:Failed++
    }
    
    # Test 3: Port 8080 is no longer in use
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/" -TimeoutSec 2 -ErrorAction SilentlyContinue
        # If we get here, the service is still running (bad)
        Write-TestResult -TestName "Port 8080 is released after shutdown" -Success $false -ErrorMessage "Service still accessible"
    } catch {
        # Exception means service is not accessible (good)
        Write-TestResult -TestName "Port 8080 is released after shutdown" -Success $true
    }
    
    # Test 4: No orphaned containers remain
    try {
        $containers = docker ps -a --filter 'name=extensible-web-app' 2>&1
        $success = -not ($containers -match 'extensible-web-app')
        Write-TestResult -TestName "No orphaned containers remain" -Success $success -ErrorMessage "Containers: $containers"
    } catch {
        Write-TestResult -TestName "No orphaned containers remain" -Success $false -ErrorMessage $_.Exception.Message
    }
    
    return $true
}

function Test-RestartProcedures {
    Write-Host ""
    Write-Host "🔄 Testing container restart procedures..." -ForegroundColor Blue
    Write-Host ""
    
    # Start container again for restart test
    Write-Host "⏳ Starting container for restart test... " -NoNewline
    try {
        $result = docker compose up -d 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ PASSED" -ForegroundColor Green
            $script:Passed++
            $script:ContainerStarted = $true
            
            # Wait for container to be ready
            $attempts = 0
            $maxAttempts = 30
            while ($attempts -lt $maxAttempts) {
                try {
                    $response = Invoke-WebRequest -Uri "http://localhost:8080/" -TimeoutSec 2 -ErrorAction SilentlyContinue
                    if ($response.StatusCode -eq 200) {
                        break
                    }
                } catch {
                    # Continue waiting
                }
                Start-Sleep -Seconds 1
                $attempts++
            }
        } else {
            Write-Host "❌ FAILED" -ForegroundColor Red
            if ($Verbose) {
                Write-Host "   Error: $result" -ForegroundColor Yellow
            }
            $script:Failed++
            return $false
        }
    } catch {
        Write-Host "❌ FAILED" -ForegroundColor Red
        if ($Verbose) {
            Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        $script:Failed++
        return $false
    }
    
    # Test 1: docker-compose restart command works
    Write-Host "⏳ docker-compose restart command works... " -NoNewline
    try {
        $result = docker compose restart 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ PASSED" -ForegroundColor Green
            $script:Passed++
        } else {
            Write-Host "❌ FAILED" -ForegroundColor Red
            if ($Verbose) {
                Write-Host "   Error: $result" -ForegroundColor Yellow
            }
            $script:Failed++
        }
    } catch {
        Write-Host "❌ FAILED" -ForegroundColor Red
        if ($Verbose) {
            Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        $script:Failed++
    }
    
    # Test 2: Service remains accessible after restart
    Write-Host "⏳ Service remains accessible after restart... " -NoNewline
    $attempts = 0
    $maxAttempts = 30
    $accessible = $false
    
    while ($attempts -lt $maxAttempts) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8080/" -TimeoutSec 2 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                Write-Host "✅ PASSED" -ForegroundColor Green
                $script:Passed++
                $accessible = $true
                break
            }
        } catch {
            # Continue waiting
        }
        Start-Sleep -Seconds 1
        $attempts++
    }
    
    if (-not $accessible) {
        Write-Host "❌ FAILED (service not accessible after restart)" -ForegroundColor Red
        $script:Failed++
    }
}

# Cleanup function
function Cleanup {
    if ($script:ContainerStarted) {
        Write-Host ""
        Write-Host "🧹 Cleaning up..." -ForegroundColor Yellow
        try {
            docker compose down 2>&1 | Out-Null
        } catch {
            # Ignore cleanup errors
        }
    }
}

# Register cleanup
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { Cleanup }

try {
    # Check prerequisites
    Write-Host "🔍 Checking prerequisites..." -ForegroundColor Blue
    Write-Host ""
    
    # Check if Docker is available
    try {
        docker --version 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Docker command failed"
        }
    } catch {
        Write-Host "❌ Docker is not installed or not in PATH" -ForegroundColor Red
        exit 1
    }
    
    # Check if Docker Compose is available
    try {
        docker compose version 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Docker Compose command failed"
        }
    } catch {
        Write-Host "❌ Docker Compose is not available" -ForegroundColor Red
        exit 1
    }
    
    # Check if docker-compose.yml exists
    if (-not (Test-Path "docker-compose.yml")) {
        Write-Host "❌ docker-compose.yml not found in current directory" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ All prerequisites met" -ForegroundColor Green
    Write-Host ""
    
    # Run all test suites
    Test-DockerComposeUp
    Test-StartupProcedures
    Test-ShutdownProcedures
    Test-RestartProcedures
    
    Write-Host ""
    Write-Host "📊 Test Results: $script:Passed passed, $script:Failed failed" -ForegroundColor Cyan
    
    if ($script:Failed -gt 0) {
        Write-Host ""
        Write-Host "❌ Some deployment tests failed" -ForegroundColor Red
        exit 1
    } else {
        Write-Host ""
        Write-Host "🎉 All deployment tests passed!" -ForegroundColor Green
        Write-Host "✅ Single-command deployment is working correctly" -ForegroundColor Green
    }
    
} finally {
    Cleanup
}