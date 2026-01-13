#!/bin/bash

# Unit Tests for Nginx Configuration
# Tests static file serving functionality and proper HTTP headers and responses
# Requirements: 1.1, 1.2

set -e

echo "🧪 Running Nginx Configuration Unit Tests"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0
CONTAINER_STARTED=false

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "⏳ $test_name... "
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASSED${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAILED${NC}"
        ((FAILED++))
    fi
}

# Function to start container
start_container() {
    echo "🐳 Starting Docker container..."
    if docker-compose up -d > /dev/null 2>&1; then
        CONTAINER_STARTED=true
        echo "✅ Container started successfully"
        
        # Wait for container to be ready
        echo "⏳ Waiting for container to be ready..."
        local attempts=0
        local max_attempts=30
        
        while [ $attempts -lt $max_attempts ]; do
            if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ | grep -q "200"; then
                echo "✅ Container is ready"
                return 0
            fi
            sleep 1
            ((attempts++))
        done
        
        echo "❌ Container failed to start within timeout"
        return 1
    else
        echo "❌ Failed to start container"
        return 1
    fi
}

# Function to stop container
stop_container() {
    if [ "$CONTAINER_STARTED" = true ]; then
        echo "🛑 Stopping Docker container..."
        docker-compose down > /dev/null 2>&1
        echo "✅ Container stopped"
    fi
}

# Cleanup function
cleanup() {
    stop_container
}

# Set trap for cleanup
trap cleanup EXIT

# Start container
if ! start_container; then
    echo "Failed to start container for testing"
    exit 1
fi

echo ""
echo "Running tests..."
echo ""

# Test 1: Static file serving functionality - index.html
run_test "Should serve index.html from root URL" \
    "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/ | grep -q '200'"

# Test 2: HTML content verification
run_test "Should return HTML content with welcome message" \
    "curl -s http://localhost:8080/ | grep -q 'Welcome to Extensible Web App'"

# Test 3: CSS file serving
run_test "Should serve CSS files" \
    "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/style.css | grep -q '200'"

# Test 4: Content-Type headers
run_test "Should return correct Content-Type for HTML" \
    "curl -s -I http://localhost:8080/ | grep -i 'content-type' | grep -q 'text/html'"

run_test "Should return correct Content-Type for CSS" \
    "curl -s -I http://localhost:8080/style.css | grep -i 'content-type' | grep -q 'text/css'"

# Test 5: Security headers
run_test "Should include X-Frame-Options header" \
    "curl -s -I http://localhost:8080/ | grep -i 'x-frame-options' | grep -q 'SAMEORIGIN'"

run_test "Should include X-Content-Type-Options header" \
    "curl -s -I http://localhost:8080/ | grep -i 'x-content-type-options' | grep -q 'nosniff'"

run_test "Should include X-XSS-Protection header" \
    "curl -s -I http://localhost:8080/ | grep -i 'x-xss-protection' | grep -q '1; mode=block'"

# Test 6: Cache headers for static assets
run_test "Should set Cache-Control header for CSS files" \
    "curl -s -I http://localhost:8080/style.css | grep -i 'cache-control' | grep -q 'public'"

# Test 7: 404 handling
run_test "Should return 404 for non-existent files" \
    "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/nonexistent.html | grep -q '404'"

# Test 8: Server header
run_test "Should identify as nginx server" \
    "curl -s -I http://localhost:8080/ | grep -i 'server' | grep -q 'nginx'"

echo ""
echo "📊 Test Results: $PASSED passed, $FAILED failed"

if [ $FAILED -gt 0 ]; then
    exit 1
fi

echo ""
echo "🎉 All tests passed!"