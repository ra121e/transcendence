# Nginx Configuration Unit Tests

This directory contains unit tests for the Nginx configuration that validate static file serving functionality and proper HTTP headers and responses as required by Requirements 1.1 and 1.2.

## Test Files

### 1. Configuration Validation Tests
- **File**: `validate-nginx-config.ps1`
- **Purpose**: Validates Nginx and Docker Compose configuration files without requiring Docker to be running
- **Requirements**: PowerShell
- **Coverage**:
  - File existence validation
  - Nginx configuration syntax and directives
  - Docker Compose service configuration
  - Static content structure
  - Security headers configuration
  - Cache and compression settings

### 2. Integration Tests (Docker Required)
- **File**: `Test-NginxConfig.ps1`
- **Purpose**: Tests actual HTTP functionality when Docker container is running
- **Requirements**: Docker, Docker Compose, PowerShell
- **Coverage**:
  - HTTP response status codes
  - Content-Type headers
  - Security headers (X-Frame-Options, X-Content-Type-Options, X-XSS-Protection)
  - Cache-Control headers for static assets
  - 404 error handling
  - Server identification

### 3. Cross-Platform Tests
- **File**: `test-nginx-config.sh`
- **Purpose**: Bash script version for Unix/Linux environments
- **Requirements**: Docker, Docker Compose, curl, bash
- **Coverage**: Same as PowerShell integration tests

## Test Selection Guide

Choose the appropriate test method based on your environment:

| Environment | Recommended Test Method | Requirements |
|-------------|------------------------|--------------|
| **Development (Quick validation)** | Configuration Validation | PowerShell only |
| **Windows + Docker** | PowerShell Integration Tests | Docker, Docker Compose, PowerShell |
| **Unix/Linux + Docker** | Bash Integration Tests | Docker, Docker Compose, curl, bash |
| **CI/CD Pipeline** | Layered testing approach | Docker, Docker Compose |

## Prerequisites

### Minimum Requirements (Configuration Validation Only)
- **PowerShell** (Windows) or **Bash** (Unix/Linux)
- No Docker required

### Full Integration Testing Requirements
- **Docker** and **Docker Compose**
- **PowerShell** (Windows) or **Bash** (Unix/Linux)

## Running the Tests

### 1. Configuration Validation (No Docker Required)
**Requirements**: PowerShell only
```powershell
# Run configuration validation tests
powershell -ExecutionPolicy Bypass -File tests/validate-nginx-config.ps1 -Verbose
```

### 2. Integration Tests (Docker Required)

#### Option A: PowerShell Integration Tests (Windows)
**Requirements**: Docker, Docker Compose, PowerShell
```powershell
# Ensure Docker and Docker Compose are installed and running
docker --version
docker-compose --version

# Run PowerShell integration tests
powershell -ExecutionPolicy Bypass -File tests/Test-NginxConfig.ps1 -Verbose
```

#### Option B: Bash Integration Tests (Unix/Linux)
**Requirements**: Docker, Docker Compose, curl, bash
```bash
# Run bash tests
chmod +x tests/test-nginx-config.sh
./tests/test-nginx-config.sh
```

## Test Coverage

The unit tests validate the following aspects of the Nginx configuration:

### Static File Serving Functionality (Requirement 1.1)
- ✅ Serves index.html from root URL with HTTP 200 status
- ✅ Returns proper HTML content type headers
- ✅ Serves CSS files with correct MIME types
- ✅ Handles 404 errors for non-existent files
- ✅ Proper document root configuration
- ✅ Index file configuration

### HTTP Headers and Responses (Requirement 1.2)
- ✅ Security headers (X-Frame-Options, X-Content-Type-Options, X-XSS-Protection)
- ✅ Cache-Control headers for static assets
- ✅ Gzip compression configuration
- ✅ MIME type handling
- ✅ Server identification headers

### Configuration Validation
- ✅ Nginx configuration file syntax
- ✅ Docker Compose service configuration
- ✅ Port mapping (8080:80)
- ✅ Volume mounts for static files and configuration
- ✅ Health check configuration
- ✅ Static content structure and validity

## Test Results

### Configuration Validation Results
```
🧪 Running Nginx Configuration Validation Tests

Validating configuration files...
✅ Nginx configuration file exists
✅ Docker Compose configuration exists
✅ Static content directory exists
✅ Index.html file exists
✅ CSS file exists

Validating Nginx configuration content...
✅ Nginx configured to listen on port 80
✅ Document root properly configured
✅ Index file properly configured
✅ X-Frame-Options security header configured
✅ X-Content-Type-Options security header configured
✅ X-XSS-Protection security header configured
✅ Gzip compression enabled
✅ Cache expiration configured for static assets
✅ MIME types properly included

Validating Docker Compose configuration...
✅ Port mapping configured (8080:80)
✅ Static files volume properly mounted
✅ Nginx configuration volume properly mounted
✅ Health check configured

Validating static content...
✅ HTML5 doctype present
✅ Welcome message present in HTML
✅ CSS stylesheet properly linked
✅ CSS file contains styling rules

📊 Test Results: 22 passed, 0 failed
🎉 All configuration validations passed!
```

## Notes

- Configuration validation tests can run without Docker and validate the setup
- Integration tests require Docker to be installed and running
- Tests are designed to be minimal and focused on core functionality
- All tests reference specific requirements for traceability
- Tests validate both configuration correctness and runtime behavior