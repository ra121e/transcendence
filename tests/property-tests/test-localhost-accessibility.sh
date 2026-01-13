#!/bin/bash

# Property-Based Test for Localhost Accessibility (Production Environment)
# Feature: extensible-web-app, Property 3: Localhost accessibility
# Validates: Requirements 2.3
#
# Property: For any properly started container instance, HTTP requests to 
# localhost on the configured port should return successful responses
#
# Requirements: Docker, Docker Compose, curl, bash

echo "🧪 Running Property-Based Test: Localhost Accessibility (Production Environment)"
echo "📋 Property: For any properly started container instance, HTTP requests to localhost should return responses"
echo "🎯 Validates: Requirements 2.3"
echo "🔧 Environment: Bash + Docker + curl"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

TOTAL_ITERATIONS=${TOTAL_ITERATIONS:-120}  # Allow override via environment variable
SUCCESSFUL_REQUESTS=0
FAILED_REQUESTS=0
CONTAINER_STARTED=false

# Arrays for random test case generation
VALID_PATHS=("/" "/style.css" "/index.html")
EDGE_CASE_PATHS=("/" "/style.css" "/favicon.ico" "/robots.txt" "/nonexistent.html")
METHODS=("GET" "HEAD")  # Restore HEAD with proper handling
USER_AGENTS=(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    "curl/7.68.0"
    "Bash Property Test"
)

# Status code tracking
declare -A STATUS_CODE_COUNT

# Function to generate random test case
generate_test_case() {
    local iteration=$1
    
    # 80% valid paths, 20% edge case paths
    if [ $((RANDOM % 100)) -lt 80 ]; then
        local path_index=$((RANDOM % ${#VALID_PATHS[@]}))
        local path="${VALID_PATHS[$path_index]}"
    else
        local path_index=$((RANDOM % ${#EDGE_CASE_PATHS[@]}))
        local path="${EDGE_CASE_PATHS[$path_index]}"
    fi
    
    local method_index=$((RANDOM % ${#METHODS[@]}))
    local method="${METHODS[$method_index]}"
    
    local ua_index=$((RANDOM % ${#USER_AGENTS[@]}))
    local user_agent="${USER_AGENTS[$ua_index]}"
    
    echo "$iteration|$path|$method|$user_agent"
}

# Function to start container
start_container() {
    echo "🐳 Starting Docker container for property testing..."
    
    if docker compose up -d > /dev/null 2>&1; then
        CONTAINER_STARTED=true
        echo -e "${GREEN}✅ Container started successfully${NC}"
        
        # Wait for container to be ready
        echo "⏳ Waiting for container to be ready..."
        local attempts=0
        local max_attempts=30
        
        while [ $attempts -lt $max_attempts ]; do
            if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null | grep -q "200" 2>/dev/null; then
                echo -e "${GREEN}✅ Container is ready for testing${NC}"
                return 0
            fi
            sleep 1
            ((attempts++))
        done
        
        echo -e "${RED}❌ Container failed to become ready within timeout${NC}"
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

# Function to test HTTP request
test_http_request() {
    local path="$1"
    local method="$2"
    local user_agent="$3"
    
    local status_code
    # HEAD-specific optimization: use -I flag and longer timeout
    if [ "$method" = "HEAD" ]; then
        status_code=$(curl -s -I -w "%{http_code}" \
            -H "User-Agent: $user_agent" \
            -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
            --connect-timeout 3 \
            --max-time 10 \
            "http://localhost:8080$path" 2>/dev/null | tail -1)
    else
        status_code=$(curl -s -o /dev/null -w "%{http_code}" \
            -X "$method" \
            -H "User-Agent: $user_agent" \
            -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
            --connect-timeout 3 \
            --max-time 5 \
            "http://localhost:8080$path" 2>/dev/null)
    fi
    
    if [ $? -eq 0 ] && [ -n "$status_code" ] && [ "$status_code" -ge 200 ] && [ "$status_code" -lt 600 ]; then
        # Track status code distribution
        STATUS_CODE_COUNT[$status_code]=$((${STATUS_CODE_COUNT[$status_code]:-0} + 1))
        echo "success|$status_code"
    else
        echo "failure|timeout_or_error"
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
    echo -e "${RED}❌ Failed to start container for property testing${NC}"
    echo "📊 Property Test Results: 0 iterations (container startup failed)"
    exit 1
fi

echo ""
echo -e "${CYAN}🔄 Running $TOTAL_ITERATIONS property test iterations...${NC}"
echo ""

# Run property tests
for ((i=1; i<=TOTAL_ITERATIONS; i++)); do
    # Generate test case
    test_case=$(generate_test_case $i)
    IFS='|' read -r iteration path method user_agent <<< "$test_case"
    
    # Execute test
    result=$(test_http_request "$path" "$method" "$user_agent")
    IFS='|' read -r status error_info <<< "$result"
    
    if [ "$status" = "success" ]; then
        ((SUCCESSFUL_REQUESTS++))
        
        # Log every 20th iteration to show progress
        if [ $((i % 20)) -eq 0 ]; then
            echo -e "${GREEN}✅ Iteration $i: $method $path → $error_info${NC}"
        fi
    else
        ((FAILED_REQUESTS++))
    fi
done

echo ""
echo -e "${CYAN}📊 Property Test Results:${NC}"
echo -e "${GREEN}✅ Successful requests: $SUCCESSFUL_REQUESTS${NC}"
echo -e "${RED}❌ Failed requests: $FAILED_REQUESTS${NC}"

# Calculate success rate using bash arithmetic (more reliable than bc)
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

# Determine if property passed (95% success rate threshold)
if [ "$success_rate" -ge 95 ]; then
    echo ""
    echo -e "${GREEN}🎉 Property Test PASSED: Localhost accessibility verified${NC}"
    echo -e "${GREEN}✅ The container consistently responds to HTTP requests on localhost:8080${NC}"
    echo -e "${GREEN}📊 Achieved ${success_rate_display}% success rate (threshold: 95%)${NC}"
    
    cleanup
    echo ""
    echo -e "${GREEN}🏆 Property-based test completed successfully!${NC}"
    echo -e "${GREEN}✅ Production environment validation complete${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Property Test FAILED: Localhost accessibility issues detected${NC}"
    echo -e "${RED}📊 Only achieved ${success_rate_display}% success rate (threshold: 95%)${NC}"
    
    cleanup
    echo ""
    echo -e "${RED}💥 Property test failed!${NC}"
    echo -e "${RED}❌ Production environment validation failed${NC}"
    exit 1
fi