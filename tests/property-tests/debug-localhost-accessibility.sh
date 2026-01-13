#!/bin/bash

# Debug version of Property-Based Test for Localhost Accessibility
# This version provides detailed debugging information to identify issues

echo "🔍 Debug Property-Based Test: Localhost Accessibility"
echo "📋 This version provides detailed debugging information"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

TOTAL_ITERATIONS=${TOTAL_ITERATIONS:-10}  # Default to 10 for debugging
SUCCESSFUL_REQUESTS=0
FAILED_REQUESTS=0
CONTAINER_STARTED=false

# Arrays for test case generation
VALID_PATHS=("/" "/style.css" "/index.html")
METHODS=("GET" "HEAD")

# Status code tracking
declare -A STATUS_CODE_COUNT
declare -a FAILED_TESTS

echo "🔧 Debug Configuration:"
echo "   Total iterations: $TOTAL_ITERATIONS"
echo "   Test paths: ${VALID_PATHS[*]}"
echo "   HTTP methods: ${METHODS[*]}"
echo ""

# Function to start container
start_container() {
    echo "🐳 Starting Docker container for debug testing..."
    
    if docker compose up -d > /dev/null 2>&1; then
        CONTAINER_STARTED=true
        echo -e "${GREEN}✅ Container started successfully${NC}"
        
        # Wait for container to be ready with detailed logging
        echo "⏳ Waiting for container to be ready..."
        local attempts=0
        local max_attempts=15
        
        while [ $attempts -lt $max_attempts ]; do
            echo "   Attempt $((attempts + 1))/$max_attempts: Testing connection..."
            
            if curl -s -o /dev/null --connect-timeout 1 --max-time 2 http://localhost:8080/ 2>/dev/null; then
                echo -e "${GREEN}✅ Container is ready for testing${NC}"
                
                # Test basic connectivity
                echo "🔍 Testing basic connectivity:"
                curl -s -I http://localhost:8080/ | head -5
                echo ""
                return 0
            fi
            sleep 1
            ((attempts++))
        done
        
        echo -e "${RED}❌ Container failed to become ready within timeout${NC}"
        echo "🔍 Container status:"
        docker ps --filter name=extensible-web-app
        echo "🔍 Container logs:"
        docker logs --tail 10 extensible-web-app
        return 1
    else
        echo -e "${RED}❌ Failed to start container${NC}"
        return 1
    fi
}

# Function to stop container
stop_container() {
    if [ "$CONTAINER_STARTED" = true ]; then
        echo "🛑 Stopping Docker container..."
        if docker compose down > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Container stopped successfully${NC}"
        else
            echo -e "${YELLOW}⚠️ Warning: Failed to stop container cleanly${NC}"
        fi
    fi
}

# Function to test HTTP request with detailed logging
test_http_request_debug() {
    local path="$1"
    local method="$2"
    local iteration="$3"
    
    echo "🔍 Test $iteration: $method $path"
    
    # Test with verbose curl output
    local temp_file="/tmp/curl_debug_$$"
    local status_code
    
    status_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -X "$method" \
        -H "User-Agent: Debug Test" \
        -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
        --connect-timeout 1 \
        --max-time 2 \
        --write-out "Time: %{time_total}s, Size: %{size_download} bytes\n" \
        "http://localhost:8080$path" 2>"$temp_file")
    
    local curl_exit_code=$?
    
    if [ $curl_exit_code -eq 0 ] && [ -n "$status_code" ] && [ "$status_code" -ge 200 ] && [ "$status_code" -lt 600 ]; then
        echo -e "   ${GREEN}✅ Success: HTTP $status_code${NC}"
        STATUS_CODE_COUNT[$status_code]=$((${STATUS_CODE_COUNT[$status_code]:-0} + 1))
        ((SUCCESSFUL_REQUESTS++))
    else
        echo -e "   ${RED}❌ Failed: curl exit code $curl_exit_code, HTTP status: $status_code${NC}"
        if [ -s "$temp_file" ]; then
            echo "   Error details: $(cat "$temp_file")"
        fi
        FAILED_TESTS+=("Test $iteration: $method $path - curl exit $curl_exit_code, HTTP $status_code")
        ((FAILED_REQUESTS++))
    fi
    
    rm -f "$temp_file"
    echo ""
}

# Cleanup function
cleanup() {
    stop_container
}

# Set trap for cleanup
trap cleanup EXIT

# Start container
if ! start_container; then
    echo -e "${RED}❌ Failed to start container for debug testing${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}🔄 Running $TOTAL_ITERATIONS debug test iterations...${NC}"
echo ""

# Run debug tests
for ((i=1; i<=TOTAL_ITERATIONS; i++)); do
    # Simple test case generation for debugging
    path_index=$((i % ${#VALID_PATHS[@]}))
    path="${VALID_PATHS[$path_index]}"
    
    method_index=$((i % ${#METHODS[@]}))
    method="${METHODS[$method_index]}"
    
    test_http_request_debug "$path" "$method" "$i"
done

echo ""
echo -e "${CYAN}📊 Debug Test Results:${NC}"
echo -e "${GREEN}✅ Successful requests: $SUCCESSFUL_REQUESTS${NC}"
echo -e "${RED}❌ Failed requests: $FAILED_REQUESTS${NC}"

# Calculate success rate using bash arithmetic
if [ $TOTAL_ITERATIONS -gt 0 ]; then
    success_rate=$((SUCCESSFUL_REQUESTS * 100 / TOTAL_ITERATIONS))
    success_rate_decimal=$((SUCCESSFUL_REQUESTS * 1000 / TOTAL_ITERATIONS % 10))
    success_rate_display="${success_rate}.${success_rate_decimal}"
else
    success_rate_display="0.0"
    success_rate=0
fi

echo -e "${YELLOW}📈 Success rate: ${success_rate_display}%${NC}"

echo ""
echo -e "${CYAN}📋 Status Code Distribution:${NC}"
for status_code in $(printf '%s\n' "${!STATUS_CODE_COUNT[@]}" | sort -n); do
    count=${STATUS_CODE_COUNT[$status_code]}
    if [ $TOTAL_ITERATIONS -gt 0 ]; then
        percentage=$((count * 100 / TOTAL_ITERATIONS))
        percentage_decimal=$((count * 1000 / TOTAL_ITERATIONS % 10))
        percentage_display="${percentage}.${percentage_decimal}"
    else
        percentage_display="0.0"
    fi
    echo "   $status_code: $count requests (${percentage_display}%)"
done

if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}📋 Failed Test Details:${NC}"
    for failed_test in "${FAILED_TESTS[@]}"; do
        echo "   • $failed_test"
    done
fi

cleanup

echo ""
if [ "$success_rate" -ge 95 ]; then
    echo -e "${GREEN}🎉 Debug Test PASSED${NC}"
    exit 0
else
    echo -e "${RED}💥 Debug Test FAILED${NC}"
    echo -e "${RED}📊 Success rate ${success_rate_display}% is below 95% threshold${NC}"
    exit 1
fi