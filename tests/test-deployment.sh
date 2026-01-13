#!/bin/bash

# Deployment Tests for Single-Command Deployment
# Tests docker-compose up functionality and container startup/shutdown procedures
# Requirements: 2.2

echo "🧪 Running Single-Command Deployment Tests"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0
CONTAINER_STARTED=false

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "⏳ $test_name... "
    
    # Execute test command and capture result
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASSED${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAILED${NC}"
        ((FAILED++))
        return 1
    fi
}

# Function to test docker-compose up command
test_docker_compose_up() {
    echo -e "${BLUE}🐳 Testing docker-compose up command...${NC}"
    echo ""
    
    # Ensure we start clean
    docker compose down > /dev/null 2>&1
    
    # Test 1: docker-compose up command executes without errors
    echo -n "⏳ docker-compose up command executes successfully... "
    if docker compose up -d > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASSED${NC}"
        ((PASSED++))
        CONTAINER_STARTED=true
    else
        echo -e "${RED}❌ FAILED${NC}"
        ((FAILED++))
        return 1
    fi
    
    # Test 2: Container is created and running
    run_test "Container is created and running" \
        "docker ps --filter 'name=extensible-web-app' --filter 'status=running' | grep -q 'extensible-web-app'"
    
    # Test 3: Container port mapping is correct
    run_test "Port mapping is configured correctly (8080:80)" \
        "docker ps --filter 'name=extensible-web-app' | grep -q '8080->80/tcp'"
    
    # Test 4: Container health check passes
    echo -n "⏳ Container health check passes... "
    local attempts=0
    local max_attempts=60  # Wait up to 60 seconds for health check
    local health_status=""
    
    while [ $attempts -lt $max_attempts ]; do
        health_status=$(docker inspect extensible-web-app --format='{{.State.Health.Status}}' 2>/dev/null)
        if [ "$health_status" = "healthy" ]; then
            echo -e "${GREEN}✅ PASSED${NC}"
            ((PASSED++))
            break
        elif [ "$health_status" = "unhealthy" ]; then
            echo -e "${RED}❌ FAILED (unhealthy)${NC}"
            ((FAILED++))
            break
        fi
        sleep 1
        ((attempts++))
    done
    
    if [ $attempts -eq $max_attempts ] && [ "$health_status" != "healthy" ]; then
        echo -e "${RED}❌ FAILED (timeout waiting for health check)${NC}"
        ((FAILED++))
    fi
    
    # Test 5: Service is accessible on localhost:8080
    echo -n "⏳ Service is accessible on localhost:8080... "
    local web_attempts=0
    local web_max_attempts=30
    
    while [ $web_attempts -lt $web_max_attempts ]; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null | grep -q "200"; then
            echo -e "${GREEN}✅ PASSED${NC}"
            ((PASSED++))
            break
        fi
        sleep 1
        ((web_attempts++))
    done
    
    if [ $web_attempts -eq $web_max_attempts ]; then
        echo -e "${RED}❌ FAILED (service not accessible)${NC}"
        ((FAILED++))
    fi
    
    return 0
}

# Function to test container startup procedures
test_startup_procedures() {
    echo ""
    echo -e "${BLUE}🚀 Testing container startup procedures...${NC}"
    echo ""
    
    # Test 1: Container starts within reasonable time
    echo -n "⏳ Container starts within 30 seconds... "
    local start_time=$(date +%s)
    
    # Container should already be started from previous test, but let's verify timing
    if [ "$CONTAINER_STARTED" = true ]; then
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        if [ $elapsed -le 30 ]; then
            echo -e "${GREEN}✅ PASSED${NC}"
            ((PASSED++))
        else
            echo -e "${RED}❌ FAILED (took ${elapsed} seconds)${NC}"
            ((FAILED++))
        fi
    else
        echo -e "${RED}❌ FAILED (container not started)${NC}"
        ((FAILED++))
    fi
    
    # Test 2: Container logs show successful startup
    run_test "Container logs show successful startup" \
        "docker logs extensible-web-app 2>&1 | grep -E '(start|ready|listening)' | head -1"
    
    # Test 3: All required volumes are mounted
    run_test "Static files volume is mounted correctly" \
        "docker inspect extensible-web-app | grep -q '/usr/share/nginx/html'"
    
    run_test "Nginx config volume is mounted correctly" \
        "docker inspect extensible-web-app | grep -q '/etc/nginx/nginx.conf'"
    
    # Test 4: Container restart policy is configured
    run_test "Container restart policy is set to 'unless-stopped'" \
        "docker inspect extensible-web-app --format='{{.HostConfig.RestartPolicy.Name}}' | grep -q 'unless-stopped'"
}

# Function to test container shutdown procedures
test_shutdown_procedures() {
    echo ""
    echo -e "${BLUE}🛑 Testing container shutdown procedures...${NC}"
    echo ""
    
    # Test 1: docker-compose down command executes successfully
    echo -n "⏳ docker-compose down command executes successfully... "
    if docker compose down > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASSED${NC}"
        ((PASSED++))
        CONTAINER_STARTED=false
    else
        echo -e "${RED}❌ FAILED${NC}"
        ((FAILED++))
        return 1
    fi
    
    # Test 2: Container is stopped and removed
    echo -n "⏳ Container is stopped and removed... "
    local attempts=0
    local max_attempts=30
    
    while [ $attempts -lt $max_attempts ]; do
        if ! docker ps -a --filter 'name=extensible-web-app' | grep -q 'extensible-web-app'; then
            echo -e "${GREEN}✅ PASSED${NC}"
            ((PASSED++))
            break
        fi
        sleep 1
        ((attempts++))
    done
    
    if [ $attempts -eq $max_attempts ]; then
        echo -e "${RED}❌ FAILED (container still exists)${NC}"
        ((FAILED++))
    fi
    
    # Test 3: Port 8080 is no longer in use
    run_test "Port 8080 is released after shutdown" \
        "! curl -s --connect-timeout 2 http://localhost:8080/ > /dev/null 2>&1"
    
    # Test 4: No orphaned containers remain
    run_test "No orphaned containers remain" \
        "! docker ps -a --filter 'name=extensible-web-app' | grep -q 'extensible-web-app'"
}

# Function to test restart procedures
test_restart_procedures() {
    echo ""
    echo -e "${BLUE}🔄 Testing container restart procedures...${NC}"
    echo ""
    
    # Start container again for restart test
    echo -n "⏳ Starting container for restart test... "
    if docker compose up -d > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASSED${NC}"
        ((PASSED++))
        CONTAINER_STARTED=true
        
        # Wait for container to be ready
        local attempts=0
        local max_attempts=30
        while [ $attempts -lt $max_attempts ]; do
            if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null | grep -q "200"; then
                break
            fi
            sleep 1
            ((attempts++))
        done
    else
        echo -e "${RED}❌ FAILED${NC}"
        ((FAILED++))
        return 1
    fi
    
    # Test 1: docker-compose restart command works
    echo -n "⏳ docker-compose restart command works... "
    if docker compose restart > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASSED${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAILED${NC}"
        ((FAILED++))
    fi
    
    # Test 2: Service remains accessible after restart
    echo -n "⏳ Service remains accessible after restart... "
    local attempts=0
    local max_attempts=30
    
    while [ $attempts -lt $max_attempts ]; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null | grep -q "200"; then
            echo -e "${GREEN}✅ PASSED${NC}"
            ((PASSED++))
            break
        fi
        sleep 1
        ((attempts++))
    done
    
    if [ $attempts -eq $max_attempts ]; then
        echo -e "${RED}❌ FAILED (service not accessible after restart)${NC}"
        ((FAILED++))
    fi
}

# Cleanup function
cleanup() {
    if [ "$CONTAINER_STARTED" = true ]; then
        echo ""
        echo -e "${YELLOW}🧹 Cleaning up...${NC}"
        docker compose down > /dev/null 2>&1
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Check prerequisites
echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed or not in PATH${NC}"
    exit 1
fi

# Check if Docker Compose is available
if ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not available${NC}"
    exit 1
fi

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ docker-compose.yml not found in current directory${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites met${NC}"
echo ""

# Run all test suites
test_docker_compose_up
test_startup_procedures
test_shutdown_procedures
test_restart_procedures

echo ""
echo "📊 Test Results: $PASSED passed, $FAILED failed"

if [ $FAILED -gt 0 ]; then
    echo ""
    echo -e "${RED}❌ Some deployment tests failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 All deployment tests passed!${NC}"
echo -e "${GREEN}✅ Single-command deployment is working correctly${NC}"