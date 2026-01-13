# Deployment Configuration Validation Tests
# Validates docker-compose configuration and deployment setup without requiring Docker
# Requirements: 2.2

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

Write-Host "🧪 Running Deployment Configuration Validation Tests" -ForegroundColor Cyan
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

function Test-DockerComposeConfiguration {
    Write-Host "🐳 Testing Docker Compose configuration..." -ForegroundColor Blue
    Write-Host ""
    
    # Test 1: docker-compose.yml file exists
    $dockerComposeExists = Test-Path "docker-compose.yml"
    Write-TestResult -TestName "docker-compose.yml file exists" -Success $dockerComposeExists
    
    if (-not $dockerComposeExists) {
        return $false
    }
    
    # Read and parse docker-compose.yml
    try {
        $dockerComposeContent = Get-Content "docker-compose.yml" -Raw
        
        # Test 2: Contains version specification
        $hasVersion = $dockerComposeContent -match "version:\s*['`"]?3\.\d+['`"]?"
        Write-TestResult -TestName "Contains valid version specification" -Success $hasVersion -ErrorMessage "Version not found or invalid"
        
        # Test 3: Contains services section
        $hasServices = $dockerComposeContent -match "services:"
        Write-TestResult -TestName "Contains services section" -Success $hasServices
        
        # Test 4: Contains web service
        $hasWebService = $dockerComposeContent -match "web:"
        Write-TestResult -TestName "Contains web service definition" -Success $hasWebService
        
        # Test 5: Uses nginx:alpine image
        $hasNginxImage = $dockerComposeContent -match "image:\s*nginx:alpine"
        Write-TestResult -TestName "Uses nginx:alpine image" -Success $hasNginxImage
        
        # Test 6: Has correct port mapping (8080:80)
        $hasPortMapping = $dockerComposeContent -match "8080:80"
        Write-TestResult -TestName "Has correct port mapping (8080:80)" -Success $hasPortMapping
        
        # Test 7: Has static files volume mount
        $hasStaticVolume = $dockerComposeContent -match "./static:/usr/share/nginx/html"
        Write-TestResult -TestName "Has static files volume mount" -Success $hasStaticVolume
        
        # Test 8: Has nginx config volume mount
        $hasConfigVolume = $dockerComposeContent -match "./nginx.conf:/etc/nginx/nginx.conf"
        Write-TestResult -TestName "Has nginx config volume mount" -Success $hasConfigVolume
        
        # Test 9: Has container name
        $hasContainerName = $dockerComposeContent -match "container_name:\s*extensible-web-app"
        Write-TestResult -TestName "Has container name specified" -Success $hasContainerName
        
        # Test 10: Has restart policy
        $hasRestartPolicy = $dockerComposeContent -match "restart:\s*unless-stopped"
        Write-TestResult -TestName "Has restart policy configured" -Success $hasRestartPolicy
        
        # Test 11: Has health check configuration
        $hasHealthCheck = $dockerComposeContent -match "healthcheck:"
        Write-TestResult -TestName "Has health check configuration" -Success $hasHealthCheck
        
        if ($hasHealthCheck) {
            # Test 12: Health check has test command
            $hasHealthTest = $dockerComposeContent -match "test:\s*\[.*curl.*\]"
            Write-TestResult -TestName "Health check has test command" -Success $hasHealthTest
            
            # Test 13: Health check has interval
            $hasHealthInterval = $dockerComposeContent -match "interval:\s*\d+s"
            Write-TestResult -TestName "Health check has interval configured" -Success $hasHealthInterval
            
            # Test 14: Health check has timeout
            $hasHealthTimeout = $dockerComposeContent -match "timeout:\s*\d+s"
            Write-TestResult -TestName "Health check has timeout configured" -Success $hasHealthTimeout
        }
        
    } catch {
        Write-TestResult -TestName "Docker Compose file is valid YAML" -Success $false -ErrorMessage $_.Exception.Message
        return $false
    }
    
    return $true
}

function Test-RequiredFiles {
    Write-Host ""
    Write-Host "📁 Testing required files for deployment..." -ForegroundColor Blue
    Write-Host ""
    
    # Test 1: Static directory exists
    $staticDirExists = Test-Path "static" -PathType Container
    Write-TestResult -TestName "Static directory exists" -Success $staticDirExists
    
    # Test 2: index.html exists
    $indexExists = Test-Path "static/index.html"
    Write-TestResult -TestName "index.html exists in static directory" -Success $indexExists
    
    # Test 3: style.css exists
    $cssExists = Test-Path "static/style.css"
    Write-TestResult -TestName "style.css exists in static directory" -Success $cssExists
    
    # Test 4: nginx.conf exists
    $nginxConfigExists = Test-Path "nginx.conf"
    Write-TestResult -TestName "nginx.conf exists in root directory" -Success $nginxConfigExists
    
    # Test 5: Validate HTML content if file exists
    if ($indexExists) {
        try {
            $htmlContent = Get-Content "static/index.html" -Raw
            
            $hasDoctype = $htmlContent -match "<!DOCTYPE html>"
            Write-TestResult -TestName "index.html has HTML5 doctype" -Success $hasDoctype
            
            $hasWelcomeMessage = $htmlContent -match "Welcome to Extensible Web App"
            Write-TestResult -TestName "index.html contains welcome message" -Success $hasWelcomeMessage
            
            $hasCssLink = $htmlContent -match "style\.css"
            Write-TestResult -TestName "index.html links to style.css" -Success $hasCssLink
            
        } catch {
            Write-TestResult -TestName "index.html is readable" -Success $false -ErrorMessage $_.Exception.Message
        }
    }
    
    # Test 6: Validate nginx config if file exists
    if ($nginxConfigExists) {
        try {
            $nginxContent = Get-Content "nginx.conf" -Raw
            
            $hasListenPort = $nginxContent -match "listen\s+80"
            Write-TestResult -TestName "nginx.conf listens on port 80" -Success $hasListenPort
            
            $hasDocumentRoot = $nginxContent -match "/usr/share/nginx/html"
            Write-TestResult -TestName "nginx.conf has correct document root" -Success $hasDocumentRoot
            
            $hasIndexFile = $nginxContent -match "index\s+index\.html"
            Write-TestResult -TestName "nginx.conf has index file configured" -Success $hasIndexFile
            
        } catch {
            Write-TestResult -TestName "nginx.conf is readable" -Success $false -ErrorMessage $_.Exception.Message
        }
    }
}

function Test-DeploymentCommands {
    Write-Host ""
    Write-Host "⚙️ Testing deployment command structure..." -ForegroundColor Blue
    Write-Host ""
    
    # Test 1: Validate that docker-compose.yml supports 'docker compose up' command
    if (Test-Path "docker-compose.yml") {
        try {
            $dockerComposeContent = Get-Content "docker-compose.yml" -Raw
            
            # Check for modern Docker Compose syntax compatibility
            $hasModernSyntax = $dockerComposeContent -match "version:\s*['`"]?3\.\d+['`"]?"
            Write-TestResult -TestName "Configuration supports modern 'docker compose' command" -Success $hasModernSyntax
            
            # Check for single-command deployment readiness
            $hasAllRequiredSections = ($dockerComposeContent -match "services:") -and 
                                     ($dockerComposeContent -match "web:") -and
                                     ($dockerComposeContent -match "image:")
            Write-TestResult -TestName "Configuration ready for single-command deployment" -Success $hasAllRequiredSections
            
            # Check for proper volume mounts (required for deployment to work)
            $hasRequiredVolumes = ($dockerComposeContent -match "./static:/usr/share/nginx/html") -and
                                 ($dockerComposeContent -match "./nginx.conf:/etc/nginx/nginx.conf")
            Write-TestResult -TestName "All required volumes configured for deployment" -Success $hasRequiredVolumes
            
        } catch {
            Write-TestResult -TestName "Docker Compose configuration is valid" -Success $false -ErrorMessage $_.Exception.Message
        }
    }
    
    # Test 2: Check README.md has deployment instructions
    if (Test-Path "README.md") {
        try {
            $readmeContent = Get-Content "README.md" -Raw
            
            $hasDockerComposeUp = $readmeContent -match "docker compose up"
            Write-TestResult -TestName "README.md contains 'docker compose up' instructions" -Success $hasDockerComposeUp
            
            $hasDockerComposeDown = $readmeContent -match "docker compose down"
            Write-TestResult -TestName "README.md contains 'docker compose down' instructions" -Success $hasDockerComposeDown
            
            $hasPortInfo = $readmeContent -match "8080"
            Write-TestResult -TestName "README.md mentions port 8080" -Success $hasPortInfo
            
        } catch {
            Write-TestResult -TestName "README.md is readable" -Success $false -ErrorMessage $_.Exception.Message
        }
    }
}

function Test-StartupShutdownConfiguration {
    Write-Host ""
    Write-Host "🔄 Testing startup and shutdown configuration..." -ForegroundColor Blue
    Write-Host ""
    
    if (Test-Path "docker-compose.yml") {
        try {
            $dockerComposeContent = Get-Content "docker-compose.yml" -Raw
            
            # Test startup configuration
            $hasRestartPolicy = $dockerComposeContent -match "restart:\s*unless-stopped"
            Write-TestResult -TestName "Container configured for automatic restart" -Success $hasRestartPolicy
            
            $hasHealthCheck = $dockerComposeContent -match "healthcheck:"
            Write-TestResult -TestName "Health check configured for startup validation" -Success $hasHealthCheck
            
            if ($hasHealthCheck) {
                $hasStartPeriod = $dockerComposeContent -match "start_period:\s*\d+s"
                Write-TestResult -TestName "Health check has start period configured" -Success $hasStartPeriod
                
                $hasRetries = $dockerComposeContent -match "retries:\s*\d+"
                Write-TestResult -TestName "Health check has retries configured" -Success $hasRetries
            }
            
            # Test shutdown configuration
            $hasContainerName = $dockerComposeContent -match "container_name:"
            Write-TestResult -TestName "Container name specified for clean shutdown" -Success $hasContainerName
            
            # Test that volumes are read-only where appropriate
            $hasReadOnlyVolumes = $dockerComposeContent -match ":ro"
            Write-TestResult -TestName "Static volumes configured as read-only" -Success $hasReadOnlyVolumes
            
        } catch {
            Write-TestResult -TestName "Startup/shutdown configuration is valid" -Success $false -ErrorMessage $_.Exception.Message
        }
    }
}

# Main execution
Write-Host "🔍 Validating deployment configuration..." -ForegroundColor Blue
Write-Host ""

# Note about environment
Write-Host "ℹ️  Running in development environment (Docker not required)" -ForegroundColor Yellow
Write-Host "   This test validates configuration files without starting containers" -ForegroundColor Yellow
Write-Host ""

# Run all test suites
Test-DockerComposeConfiguration
Test-RequiredFiles
Test-DeploymentCommands
Test-StartupShutdownConfiguration

Write-Host ""
Write-Host "📊 Test Results: $script:Passed passed, $script:Failed failed" -ForegroundColor Cyan

if ($script:Failed -gt 0) {
    Write-Host ""
    Write-Host "❌ Some deployment configuration tests failed" -ForegroundColor Red
    Write-Host "   Fix the configuration issues before attempting deployment" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host ""
    Write-Host "🎉 All deployment configuration tests passed!" -ForegroundColor Green
    Write-Host "✅ Configuration is ready for single-command deployment" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Next steps:" -ForegroundColor Cyan
    Write-Host "   1. Install Docker and Docker Compose" -ForegroundColor White
    Write-Host "   2. Run: docker compose up -d" -ForegroundColor White
    Write-Host "   3. Visit: http://localhost:8080" -ForegroundColor White
    Write-Host "   4. Stop: docker compose down" -ForegroundColor White
}