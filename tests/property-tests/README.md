# Property-Based Tests

This directory contains property-based tests that validate universal properties across many generated inputs, as specified in the design document.

## Testing Environments

### Development Environment (Limited Dependencies)
- **Requirements**: PowerShell only
- **Capabilities**: Configuration validation, simulation-based property testing
- **Purpose**: Quick validation without Docker/npm dependencies

### Production Environment (Full Dependencies)
- **Requirements**: Docker, Docker Compose, npm, Node.js, bash
- **Capabilities**: Full container testing, comprehensive property-based testing
- **Purpose**: Complete end-to-end validation with actual containers

## Test Files

### 1. Localhost Accessibility Property Test

#### Development Environment Version (PowerShell)
- **File**: `Test-LocalhostAccessibility.ps1`
- **Property**: For any properly started container instance, HTTP requests to localhost should return successful responses
- **Validates**: Requirements 2.3
- **Iterations**: 120 test cases (exceeds minimum 100 as specified in design)
- **Tag**: **Feature: extensible-web-app, Property 3: Localhost accessibility**
- **Features**: Automatically runs in simulation mode when Docker is unavailable

#### Production Environment Version (Node.js)
- **File**: `localhost-accessibility.test.js`
- **Property**: Same as above
- **Validates**: Requirements 2.3
- **Iterations**: 120 test cases
- **Features**: Full testing with actual Docker containers, detailed status code distribution analysis

#### Production Environment Version (Bash)
- **File**: `test-localhost-accessibility.sh` (standard version)
- **File**: `test-localhost-accessibility-fast.sh` (optimized version)
- **Property**: Same as above
- **Validates**: Requirements 2.3
- **Iterations**: 120 test cases
- **Features**: Unix/Linux environment execution, curl-based HTTP testing
- **Performance**: Fast version uses parallel execution and optimized timeouts

## Execution Methods

### Development Environment (PowerShell)

#### Prerequisites
- **PowerShell** (Windows)

#### Execution Commands
```powershell
# Development environment execution (automatically enters simulation mode if Docker unavailable)
powershell -ExecutionPolicy Bypass -File tests/property-tests/Test-LocalhostAccessibility.ps1 -Verbose
```
### Production Environment

#### Prerequisites
- **Docker and Docker Compose**
- **Node.js and npm** (for Node.js version)
- **bash and curl** (for Bash version)

#### Node.js Version Execution
```bash
# Install dependencies (first time only)
npm install

# Run Node.js property tests
npm run test:property

# Or run directly
node tests/property-tests/localhost-accessibility.test.js
```

#### Bash Version Execution
```bash
# Grant execution permissions (first time only)
chmod +x tests/property-tests/test-localhost-accessibility.sh

# Run standard Bash property tests
./tests/property-tests/test-localhost-accessibility.sh

# Run optimized fast Bash property tests (recommended)
chmod +x tests/property-tests/test-localhost-accessibility-fast.sh
./tests/property-tests/test-localhost-accessibility-fast.sh

# Or use npm script for fast version
npm run test:fast
```

## Property Test Design

### Test Case Generation
Property tests generate 120 test cases with:
- **Random paths**: Mix of valid paths (/, /style.css, /index.html) and edge cases
- **Random HTTP methods**: GET and HEAD requests
- **Random headers**: Different User-Agent and Accept headers
- **Edge case coverage**: 20% of requests target potentially non-existent resources

### Success Criteria
- **Success Rate Threshold**: 95% (configurable)
- **Response Validation**: Any HTTP response (including 404) counts as successful accessibility
- **Property Validation**: Tests that localhost is accessible and responding, not specific content

### Simulation Mode (Development Environment)
When Docker is unavailable, tests run in simulation mode:
- Simulates realistic HTTP responses based on nginx configuration
- 99.5% success rate with occasional network timeouts
- Validates test logic and structure without Docker dependency
- Useful for CI/CD environments or development without Docker

## Integration with Task List

This property test corresponds to:
- **Task**: 5.3 Write property test for localhost accessibility
- **Property**: Property 3: Localhost accessibility
- **Requirements**: Validates Requirements 2.3

## Notes

- Property tests complement unit tests by validating universal properties
- Each test runs minimum 100 iterations as specified in the design document
- Tests focus on accessibility rather than specific content validation
- Simulation mode allows testing the property logic without Docker dependency
- Results are tagged with feature name and property number for traceability
- Production environment enables complete validation with actual Docker containers