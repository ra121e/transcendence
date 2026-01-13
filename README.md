# Extensible Web App

A minimal containerized web application foundation that serves static content using Nginx and Docker Compose. This system provides a simple starting point for future feature development while maintaining production-ready configuration and comprehensive testing.

## Features

- **Static Content Serving**: HTML/CSS content with proper MIME types and caching
- **Containerized Deployment**: Docker-based deployment with health checks
- **Single-Command Startup**: Simple `docker compose up` deployment
- **Responsive Design**: Mobile-friendly CSS styling
- **Security Headers**: X-Frame-Options, X-Content-Type-Options, X-XSS-Protection
- **Performance Optimization**: Gzip compression and static asset caching
- **Chrome Compatibility**: Tested and verified with Google Chrome
- **Extensible Architecture**: Designed for future backend API and database integration
- **Comprehensive Testing**: Multi-environment testing strategy with property-based tests

## System Requirements

### Minimum Requirements (Development)
- **Operating System**: Windows 10+ (PowerShell 5.1+) or Linux/macOS (bash)
- **Web Browser**: Google Chrome (recommended) or any modern browser
- **Development Tools**: PowerShell (Windows) for configuration validation

### Full Requirements (Production/CI)
- **Docker**: Version 20.10+ 
- **Docker Compose**: Version 2.0+ (uses modern `docker compose` command)
- **Node.js**: Version 16+ (for property-based testing)
- **npm**: Version 8+ (for test dependencies)
- **Operating System**: Linux/macOS (bash) or Windows with WSL2
- **Web Browser**: Google Chrome (for compatibility testing)

### Hardware Requirements
- **RAM**: 512MB minimum (for Docker container)
- **Disk Space**: 100MB minimum
- **Network**: Internet connection for Docker image downloads

## Quick Start

### Prerequisites Check
Before starting, verify your system meets the requirements:

```bash
# Check Docker installation
docker --version
docker compose version

# Check if port 8080 is available
# Windows PowerShell:
netstat -an | findstr :8080
# Linux/macOS:
lsof -i :8080
```

### Installation and Deployment

1. **Clone or download this project**
   ```bash
   git clone <repository-url>
   cd extensible-web-app
   ```

2. **Verify project structure**
   ```bash
   # Ensure all required files are present
   ls -la
   # Should show: docker-compose.yml, nginx.conf, static/, README.md
   ```

3. **Start the application**
   ```bash
   # Start in detached mode (recommended)
   docker compose up -d
   
   # Or start with logs visible (for debugging)
   docker compose up
   ```

4. **Verify deployment**
   ```bash
   # Check container status
   docker compose ps
   
   # Check container health
   docker inspect extensible-web-app --format='{{.State.Health.Status}}'
   ```

5. **Access the application**
   - Open your browser and visit: **http://localhost:8080**
   - You should see the welcome page with "Welcome to Extensible Web App"

6. **Stop the application**
   ```bash
   # Stop and remove containers
   docker compose down
   
   # Stop, remove containers, and remove volumes
   docker compose down -v
   ```

### Alternative Port Configuration
If port 8080 is already in use, modify `docker-compose.yml`:
```yaml
ports:
  - "3000:80"  # Use port 3000 instead of 8080
```

## Project Structure

```
extensible-web-app/
├── docker-compose.yml      # Container orchestration configuration
├── nginx.conf             # Nginx web server configuration
├── package.json           # Node.js dependencies for testing
├── .env.example           # Environment variables template (future use)
├── README.md              # This documentation file
├── static/                # Static content directory
│   ├── index.html         # Main welcome page
│   └── style.css          # Basic CSS styling
└── tests/                 # Comprehensive test suite
    ├── README.md          # Testing documentation
    ├── validate-nginx-config.ps1      # PowerShell config validation
    ├── validate-deployment-config.ps1 # PowerShell deployment validation
    ├── test-nginx-config.sh           # Bash integration tests
    ├── test-deployment.sh             # Bash deployment tests
    ├── test-deployment-lenient.sh     # Bash deployment tests (lenient)
    └── property-tests/     # Property-based testing directory
        ├── README.md       # Property testing documentation
        ├── Test-LocalhostAccessibility.ps1    # PowerShell property tests
        ├── localhost-accessibility.test.js    # Node.js property tests
        ├── test-localhost-accessibility.sh    # Bash property tests
        ├── test-localhost-accessibility-fast.sh # Optimized bash tests
        └── debug-localhost-accessibility.sh   # Debug utilities
```

### Key Configuration Files

- **`docker-compose.yml`**: Defines the Nginx service, port mapping (8080:80), volume mounts, and health checks
- **`nginx.conf`**: Nginx configuration with security headers, gzip compression, caching, and static file serving
- **`static/index.html`**: Main welcome page with responsive HTML5 structure
- **`static/style.css`**: CSS styling with responsive design and modern aesthetics
- **`package.json`**: Node.js configuration for property-based testing dependencies

## Development

### Adding Static Content

1. **HTML Files**: Place HTML files in the `static/` directory
   ```bash
   # Example: Add a new page
   echo '<h1>About Page</h1>' > static/about.html
   # Access at: http://localhost:8080/about.html
   ```

2. **CSS Files**: Add stylesheets to the `static/` directory
   ```bash
   # CSS files are automatically served with proper MIME types
   # and cached for 1 year for performance
   ```

3. **Assets**: Create subdirectories for organized content
   ```bash
   mkdir static/images static/js
   # Files will be served with appropriate caching headers
   ```

### Modifying Configuration

#### Nginx Configuration (`nginx.conf`)
- **Document root**: `/usr/share/nginx/html` (maps to `./static`)
- **Security headers**: X-Frame-Options, X-Content-Type-Options, X-XSS-Protection
- **Compression**: Gzip enabled for text files
- **Caching**: 1-year cache for static assets (CSS, JS, images)
- **Error pages**: Custom 404 and 50x error handling

#### Container Configuration (`docker-compose.yml`)
- **Port mapping**: Change `"8080:80"` to use different host port
- **Volume mounts**: Static files and nginx.conf are mounted read-only
- **Health checks**: Container health monitored via curl
- **Restart policy**: `unless-stopped` for production reliability

#### Environment Variables (Future Use)
- **Template**: `.env.example` provides template for future configuration
- **Usage**: Environment-specific settings for database connections, API keys, etc.

### Extending the Application

This foundation is designed for incremental extension:

#### Phase 2: Backend API Integration
```yaml
# Add to docker-compose.yml
services:
  api:
    build: ./backend
    ports:
      - "3001:3000"
    environment:
      - DATABASE_URL=${DATABASE_URL}
```

#### Phase 3: Database Integration
```yaml
# Add to docker-compose.yml
services:
  database:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=${DB_NAME}
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
```

#### Phase 4: Reverse Proxy Configuration
```nginx
# Add to nginx.conf
location /api/ {
    proxy_pass http://api:3000/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

### Development Workflow

1. **Make changes** to static files in `./static/`
2. **Restart container** to see changes:
   ```bash
   docker compose restart web
   ```
3. **View logs** for debugging:
   ```bash
   docker compose logs -f web
   ```
4. **Run tests** to validate changes:
   ```bash
   # Development environment (PowerShell)
   powershell -ExecutionPolicy Bypass -File tests/validate-nginx-config.ps1
   
   # Production environment (bash + npm)
   npm run test:property
   ```

## Testing

This project includes a comprehensive test suite that supports both development and production environments with distinct tooling strategies.

### Development Environment Testing (PowerShell Only - Windows)

For local development environments without npm and Docker dependencies:

#### Configuration Validation Tests
```powershell
# Validate Nginx and Docker Compose configuration (runs without Docker)
powershell -ExecutionPolicy Bypass -File tests/validate-nginx-config.ps1 -Verbose

# Validate deployment configuration (runs without Docker)
powershell -ExecutionPolicy Bypass -File tests/validate-deployment-config.ps1 -Verbose
```

#### Property-Based Tests
```powershell
# Localhost accessibility property test (simulation mode)
powershell -ExecutionPolicy Bypass -File tests/property-tests/Test-LocalhostAccessibility.ps1 -Verbose
```

### Production Environment Testing (Docker + npm + bash - Linux/Unix)

For CI/CD pipelines and server environments with full dependencies:

#### Unit Tests (Docker Required)
```bash
# Bash integration tests
chmod +x tests/test-nginx-config.sh
./tests/test-nginx-config.sh

# Deployment tests (Bash - lenient mode, recommended)
chmod +x tests/test-deployment-lenient.sh
./tests/test-deployment-lenient.sh

# Deployment tests (Bash - strict mode)
chmod +x tests/test-deployment.sh
./tests/test-deployment.sh
```

#### Property-Based Tests (Docker Required)
```bash
# Node.js property tests
npm install
npm run test:property

# Bash property tests (fast/optimized - recommended)
chmod +x tests/property-tests/test-localhost-accessibility-fast.sh
./tests/property-tests/test-localhost-accessibility-fast.sh
# Or: npm run test:fast
```

### Environment-Specific Strategy

- **Development (Windows)**: PowerShell-only execution, configuration validation without Docker
- **Production (Linux/Unix)**: Docker + npm/bash for complete container testing
- **No Duplication**: Each environment has distinct file sets to avoid maintenance overhead
- **Test Coverage**: Static file serving, HTTP headers, security headers, localhost accessibility properties

For detailed information, see `tests/README.md` and `tests/property-tests/README.md`.

## Troubleshooting

### Common Issues and Solutions

#### 1. Port 8080 Already in Use
**Symptoms**: 
- Error: "bind: address already in use"
- Container fails to start

**Solutions**:
```bash
# Option 1: Find and stop the process using port 8080
# Windows:
netstat -ano | findstr :8080
taskkill /PID <PID> /F

# Linux/macOS:
lsof -ti:8080 | xargs kill -9

# Option 2: Use a different port
# Edit docker-compose.yml:
ports:
  - "3000:80"  # Use port 3000 instead
```

#### 2. Container Won't Start
**Symptoms**:
- Container exits immediately
- Health check failures

**Diagnostic Steps**:
```bash
# Check Docker daemon status
docker info

# Check container logs
docker compose logs web

# Check container status
docker compose ps

# Inspect container details
docker inspect extensible-web-app
```

**Common Solutions**:
```bash
# Rebuild and restart
docker compose down
docker compose up --build

# Check file permissions (Linux/macOS)
chmod -R 755 static/
chmod 644 nginx.conf docker-compose.yml

# Verify Docker Compose syntax
docker compose config
```

#### 3. Health Check Issues
**Symptoms**:
- Container shows as "unhealthy"
- Intermittent connectivity issues

**Diagnostic Commands**:
```bash
# Check health status
docker inspect extensible-web-app --format='{{json .State.Health}}'

# View health check logs
docker inspect extensible-web-app --format='{{range .State.Health.Log}}{{.Output}}{{end}}'

# Manual health check
docker exec extensible-web-app curl -f http://localhost || echo "Health check failed"
```

**Solutions**:
```bash
# Wait for startup period (60 seconds)
# Health checks start after 60-second startup period

# Check if curl is available in container
docker exec extensible-web-app which curl

# Restart container if health checks consistently fail
docker compose restart web
```

#### 4. Static Files Not Loading
**Symptoms**:
- 404 errors for CSS/JS files
- Blank or unstyled pages

**Diagnostic Steps**:
```bash
# Check file structure
ls -la static/

# Check volume mount
docker inspect extensible-web-app --format='{{json .Mounts}}'

# Check nginx logs
docker compose logs web | grep -E "(error|404)"
```

**Solutions**:
```bash
# Verify file permissions
chmod 644 static/*.html static/*.css

# Restart container to remount volumes
docker compose restart web

# Check nginx configuration
docker exec extensible-web-app nginx -t
```

#### 5. Browser Compatibility Issues
**Symptoms**:
- Page doesn't display correctly
- CSS not loading properly

**Solutions**:
```bash
# Clear browser cache
# Chrome: Ctrl+Shift+R (hard refresh)

# Check Content-Type headers
curl -I http://localhost:8080/style.css

# Verify MIME types in nginx.conf
docker exec extensible-web-app cat /etc/nginx/mime.types | grep css
```

#### 6. Performance Issues
**Symptoms**:
- Slow page loading
- High resource usage

**Diagnostic Commands**:
```bash
# Check container resource usage
docker stats extensible-web-app

# Check nginx access logs
docker compose logs web | grep -E "GET|POST"

# Test response times
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:8080/
```

**Solutions**:
```bash
# Verify gzip compression is working
curl -H "Accept-Encoding: gzip" -I http://localhost:8080/

# Check cache headers
curl -I http://localhost:8080/style.css | grep -i cache

# Monitor nginx worker processes
docker exec extensible-web-app ps aux | grep nginx
```

#### 7. Docker Compose Issues
**Symptoms**:
- "docker-compose: command not found"
- Version compatibility errors

**Solutions**:
```bash
# Use modern Docker Compose command
docker compose up -d  # NOT docker-compose

# Check Docker Compose version
docker compose version

# Update Docker Compose if needed
# Follow official Docker documentation for your OS
```

#### 8. Testing Failures
**Symptoms**:
- Property tests failing
- Configuration validation errors

**Solutions**:
```bash
# Run configuration validation first
powershell -ExecutionPolicy Bypass -File tests/validate-nginx-config.ps1 -Verbose

# Check test environment
node --version
npm --version

# Run tests in debug mode
npm run test:property 2>&1 | tee test-output.log
```

### Getting Help

If you encounter issues not covered here:

1. **Check logs**: Always start with `docker compose logs web`
2. **Verify configuration**: Run `docker compose config` to validate syntax
3. **Test connectivity**: Use `curl http://localhost:8080` to test basic connectivity
4. **Run validation tests**: Use PowerShell validation scripts for quick diagnosis
5. **Check Docker status**: Ensure Docker daemon is running and healthy

### Debug Mode

For detailed debugging, start the container with verbose logging:
```bash
# Stop current container
docker compose down

# Start with debug logging
docker compose up --build
# Logs will show detailed nginx startup and request information
```

## Dependencies

### Runtime Dependencies
- **Nginx**: Alpine Linux-based web server (pulled automatically via Docker)
- **Docker**: Container runtime platform
- **Docker Compose**: Container orchestration tool

### Development Dependencies (Optional)
- **Node.js**: For property-based testing (fast-check library)
- **PowerShell**: For Windows-based configuration validation
- **Bash**: For Unix/Linux testing scripts
- **curl**: For HTTP testing and health checks

### Testing Dependencies
```json
{
  "devDependencies": {
    "fast-check": "^3.0.0"
  }
}
```

Install testing dependencies:
```bash
npm install  # Installs fast-check for property-based testing
```

## Security Considerations

### Built-in Security Features
- **Security Headers**: X-Frame-Options, X-Content-Type-Options, X-XSS-Protection
- **Read-only Volumes**: Static files and configuration mounted read-only
- **Non-root Container**: Nginx runs as non-root user inside container
- **Minimal Attack Surface**: Alpine Linux base image with minimal packages
- **Health Monitoring**: Container health checks for availability monitoring

### Production Recommendations
- **HTTPS**: Configure SSL/TLS certificates for production deployment
- **Firewall**: Restrict access to necessary ports only
- **Updates**: Regularly update Docker images and base system
- **Monitoring**: Implement log monitoring and alerting
- **Backup**: Regular backup of static content and configuration

## Performance Optimization

### Built-in Optimizations
- **Gzip Compression**: Enabled for text-based content (HTML, CSS, JS)
- **Static Asset Caching**: 1-year cache headers for CSS, JS, images
- **Efficient MIME Types**: Proper Content-Type headers for all file types
- **Keep-Alive Connections**: Persistent connections for better performance

### Monitoring Performance
```bash
# Monitor container resource usage
docker stats extensible-web-app

# Test response times
curl -w "Total time: %{time_total}s\n" -o /dev/null -s http://localhost:8080/

# Check compression effectiveness
curl -H "Accept-Encoding: gzip" -I http://localhost:8080/ | grep -i content-encoding
```

## License

This project is provided as-is for educational and development purposes. Feel free to use, modify, and distribute according to your needs.

## Contributing

This is a minimal foundation project. For contributions:
1. Ensure all tests pass before submitting changes
2. Follow the existing configuration patterns
3. Update documentation for any new features
4. Test in both development and production environments

## Support

For issues and questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review test output for diagnostic information
3. Examine container logs: `docker compose logs web`
4. Validate configuration: Run PowerShell validation scripts