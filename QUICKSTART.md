# Eve Watchman - Quick Reference

This is a quick reference guide for common deployment and management tasks.

## First Time Setup

```bash
# 1. Install Docker and Docker Compose
# Follow instructions at https://docs.docker.com/get-docker/

# 2. Clone the repository
git clone https://github.com/Greeed-islanl/eve-watchman.git
cd eve-watchman

# 3. Create configuration
make install  # or: cp .env.example .env

# 4. Edit .env file with your settings
nano .env  # or your preferred editor

# Required settings:
# - EVE_CLIENT_ID
# - EVE_CLIENT_SECRET
# - EVE_CLIENT_REDIRECT
# - EVE_SUPER_ADMINS

# 5. Start the application
make up

# 6. Access at http://localhost:8080
```

## Common Commands

```bash
# Start services
make up
# or: docker compose up -d

# Stop services
make down
# or: docker compose down

# View logs
make logs           # All services
make logs-web       # Web application only
make logs-relay     # Relay service only
make logs-db        # Database only

# Restart services
make restart
# or: docker compose restart

# Check status
make status
# or: docker compose ps

# Update application
make update

# Health check
./health-check.sh
```

## Configuration

### Using Environment Variables (Recommended for Docker)

Edit `.env` file with your configuration:

```bash
# Database
DB_PASSWORD=yourpassword

# Eve Online Application
EVE_CLIENT_ID=your_client_id
EVE_CLIENT_SECRET=your_secret
EVE_CLIENT_REDIRECT=http://yourdomain.com:8080/?core_action=callback
EVE_SUPER_ADMINS=12345,67890

# Optional
WEB_PORT=8080
SESSION_TIME=43200
```

### Using Config File

Alternatively, use the config file:

```bash
cp config/config.ini.dist config/config.ini
nano config/config.ini

# Then restart services
make restart
```

**Note:** Config file takes priority over environment variables.

## Troubleshooting

### Services won't start

```bash
# Check logs
docker compose logs

# Check if ports are available
netstat -an | grep 8080
netstat -an | grep 3306

# Restart everything
docker compose down
docker compose up -d
```

### Database connection errors

```bash
# Wait for database to be ready
docker compose ps database

# Check database logs
docker compose logs database

# Verify environment variables
cat .env | grep DB_
```

### Web application not accessible

```bash
# Check if web service is running
docker compose ps web

# Check web logs
docker compose logs web

# Verify port mapping
docker compose ps | grep web
```

### Relay not processing notifications

```bash
# Check relay logs
docker compose logs relay

# Ensure database is initialized
# Visit the web app at least once before the relay will work

# Restart relay service
docker compose restart relay
```

## Directory Structure

```
eve-watchman/
├── .env                    # Your configuration (create from .env.example)
├── .env.example            # Example configuration template
├── docker-compose.yml      # Docker orchestration
├── Dockerfile.web          # Web application container
├── Dockerfile.relay        # Relay service container
├── Makefile               # Convenience commands
├── health-check.sh        # Deployment verification script
├── DEPLOYMENT.md          # Detailed deployment guide
├── config/                # Application configuration
│   ├── config.ini.dist    # Config file template
│   └── config.php         # Config loader
├── public/                # Web root
├── scripts/Python/        # Relay scripts
└── src/                   # Application source code
```

## Port Reference

| Service  | Internal Port | Default External Port | Configurable Via |
|----------|---------------|----------------------|------------------|
| Web      | 80            | 8080                 | WEB_PORT in .env |
| Database | 3306          | 3306                 | DB_PORT in .env  |
| Relay    | N/A           | N/A                  | N/A              |

## Volume Management

```bash
# List volumes
docker volume ls | grep eve-watchman

# Backup database
docker compose exec database mysqldump -u watchman -p eve_watchman > backup.sql

# Remove all data (WARNING: Deletes database!)
docker compose down -v
```

## Security Checklist

- [ ] Changed default database password in `.env`
- [ ] Set proper `EVE_SUPER_ADMINS` character IDs
- [ ] Configure firewall to restrict access
- [ ] Use HTTPS in production (reverse proxy)
- [ ] Secure `.env` file permissions: `chmod 600 .env`
- [ ] Don't expose database port (3306) publicly
- [ ] Keep Docker images updated
- [ ] Regular backups of database

## Production Deployment

For production, consider:

1. **Use a reverse proxy** (nginx/Apache) with SSL/TLS
2. **Change default ports** if needed
3. **Set strong database passwords**
4. **Configure firewall rules**
5. **Set up regular backups**
6. **Monitor logs and resources**
7. **Use external MySQL** for better performance and backups

Example nginx reverse proxy config:

```nginx
server {
    listen 443 ssl http2;
    server_name watchman.yourdomain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Getting Help

- Check [DEPLOYMENT.md](DEPLOYMENT.md) for detailed instructions
- Review [README.md](README.md) for application details
- Check logs: `docker compose logs -f`
- Run health check: `./health-check.sh`
- Open an issue on GitHub

## Useful Docker Commands

```bash
# View resource usage
docker stats

# Clean up unused resources
docker system prune

# Rebuild from scratch
docker compose build --no-cache

# Run commands in containers
docker compose exec web bash
docker compose exec database mysql -u watchman -p
docker compose exec relay bash

# Export/Import database
docker compose exec database mysqldump -u watchman -p eve_watchman > backup.sql
docker compose exec -T database mysql -u watchman -p eve_watchman < backup.sql
```
