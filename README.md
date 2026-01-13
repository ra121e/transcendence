# Extensible Web App

A minimal containerized web application foundation that serves static content using Nginx and Docker Compose. This system provides a simple starting point for future feature development.

## Features

- Static HTML/CSS content serving
- Containerized deployment with Docker
- Single-command startup
- Responsive design
- Chrome compatibility
- Extensible architecture for future enhancements

## Requirements

- Docker
- Docker Compose
- Google Chrome (for testing)

## Quick Start

1. Clone or download this project
2. Navigate to the project directory
3. Start the application:
   ```bash
   docker compose up -d
   ```
4. Open your browser and visit: http://localhost:8080
5. To stop the application:
   ```bash
   docker compose down
   ```

## Project Structure

```
/
├── docker-compose.yml  # Container orchestration
├── nginx.conf         # Nginx web server configuration
├── static/            # Static content directory
│   ├── index.html     # Main welcome page
│   └── style.css      # Basic CSS styling
└── README.md          # This file
```

## Development

### Adding Static Content

Place your HTML, CSS, and other static files in the `static/` directory. The Nginx server will serve these files automatically.

### Modifying Configuration

- **Nginx settings**: Edit `nginx.conf`
- **Container settings**: Edit `docker-compose.yml`
- **Port mapping**: Change the port mapping in `docker-compose.yml` (default: 8080:80)

### Extending the Application

This foundation is designed to be extended with additional services:

- **Backend API**: Add a backend service container to `docker-compose.yml`
- **Database**: Add database services (PostgreSQL, MySQL, etc.)
- **Caching**: Add Redis or other caching services
- **Load Balancing**: Configure Nginx as a reverse proxy

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
If port 8080 is already in use, change the port mapping in `docker-compose.yml`:
```yaml
ports:
  - "3000:80"  # Use port 3000 instead
```

### Container Won't Start
1. Check if Docker is running
2. Verify no port conflicts exist
3. Check container logs:
   ```bash
   docker compose logs web
   ```

### Health Check Issues
If health checks fail, the container uses `curl` for health checking. If you encounter issues:
1. Check health status: `docker inspect extensible-web-app --format='{{json .State.Health}}'`
2. View recent logs: `docker logs --tail 50 extensible-web-app`
3. The health check waits 60 seconds before starting, then checks every 30 seconds

### Static Files Not Loading
1. Ensure files are in the `static/` directory
2. Check file permissions
3. Restart the container:
   ```bash
   docker compose restart
   ```

## License

This project is provided as-is for educational and development purposes.