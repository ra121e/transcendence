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
   docker-compose up -d
   ```
4. Open your browser and visit: http://localhost:8080
5. To stop the application:
   ```bash
   docker-compose down
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

## Troubleshooting

### Port Already in Use
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
   docker-compose logs web
   ```

### Static Files Not Loading
1. Ensure files are in the `static/` directory
2. Check file permissions
3. Restart the container:
   ```bash
   docker-compose restart
   ```

## License

This project is provided as-is for educational and development purposes.