# Deployment Guide for Eve Watchman

This guide explains how to deploy Eve Watchman using Docker and Docker Compose for a testing or production environment.

## Prerequisites

Before deploying Eve Watchman, ensure you have:

1. **Docker** (version 20.10 or later)
2. **Docker Compose** (version 2.0 or later)
3. **Eve Online Application** registered at [Eve Online Developers Site](https://developers.eveonline.com/)
   - Required scopes: `esi-universe.read_structures.v1`, `esi-characters.read_corporation_roles.v1`, `esi-characters.read_notifications.v1`
   - Callback URL should point to your deployment URL with `?core_action=callback` parameter

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/Greeed-islanl/eve-watchman.git
cd eve-watchman
```

### 2. Configure Environment Variables

Copy the example environment file and configure it:

```bash
cp .env.example .env
```

Edit `.env` and set the following required values:

- `EVE_CLIENT_ID`: Your Eve Online Application Client ID
- `EVE_CLIENT_SECRET`: Your Eve Online Application Client Secret
- `EVE_CLIENT_REDIRECT`: Your callback URL (e.g., `http://your-domain.com:8080/?core_action=callback`)
- `EVE_SUPER_ADMINS`: Comma-separated list of character IDs who will have super admin access

Optional configurations:
- `DB_PASSWORD`: Database password (change from default for production)
- `WEB_PORT`: Web server port (default: 8080)
- Database credentials if you want non-default values

### 3. Deploy the Application

Start all services using Docker Compose:

```bash
docker-compose up -d
```

This will:
- Build the web application container (Apache + PHP)
- Build the Python relay service container
- Start a MySQL database container
- Create necessary networks and volumes

### 4. Access the Application

Once all containers are running, access the application at:

```
http://localhost:8080
```

Or replace `localhost` with your server's IP address or domain name.

### 5. Initial Setup

1. Access the web application for the first time to initialize the database
2. Log in using your Eve Online character (must be one of the Super Admin character IDs)
3. Add relay characters through the character management interface
4. Create relays and configure notifications

## Managing the Deployment

### View Running Containers

```bash
docker-compose ps
```

### View Logs

View logs for all services:
```bash
docker-compose logs -f
```

View logs for a specific service:
```bash
docker-compose logs -f web
docker-compose logs -f relay
docker-compose logs -f database
```

### Stop the Application

```bash
docker-compose down
```

To also remove volumes (will delete database data):
```bash
docker-compose down -v
```

### Restart a Service

```bash
docker-compose restart web
docker-compose restart relay
docker-compose restart database
```

### Update the Application

```bash
# Pull latest changes
git pull

# Rebuild and restart containers
docker-compose down
docker-compose up -d --build
```

## Architecture

The deployment consists of three services:

1. **web**: Apache 2.4 + PHP 8.2 serving the web application
2. **relay**: Python 3.11 running the notification relay script every 60 seconds
3. **database**: MySQL 8.0 with legacy authentication for PDO compatibility

All services communicate over a dedicated Docker network (`eve-watchman-network`).

## Configuration Options

### Using Config File Instead of Environment Variables

If you prefer to use a config file instead of environment variables:

1. Copy the example config file:
   ```bash
   cp config/config.ini.dist config/config.ini
   ```

2. Edit `config/config.ini` with your settings

3. Remove or comment out the environment variables in `docker-compose.yml`

Note: The config file takes priority over environment variables.

### Customizing Ports

To change the web server port, edit the `WEB_PORT` value in `.env`:

```bash
WEB_PORT=8080  # Change to your desired port
```

### Enabling Timerboards

To enable timerboard integration:

1. Edit `.env` and set:
   ```bash
   TIMERBOARDS_ENABLED=1
   TIMERBOARDS_APPROVED_TYPES=RC2
   TIMERBOARDS_APPROVED_DOMAINS=your-timerboard-domain.com
   ```

2. Restart the services:
   ```bash
   docker-compose restart
   ```

## Troubleshooting

### Database Connection Issues

If the web application can't connect to the database:

1. Check if the database container is healthy:
   ```bash
   docker-compose ps
   ```

2. Verify database credentials in `.env` match between services

3. Check database logs:
   ```bash
   docker-compose logs database
   ```

### Web Application Not Accessible

1. Check if the web container is running:
   ```bash
   docker-compose ps web
   ```

2. Verify the port is not already in use:
   ```bash
   netstat -an | grep 8080
   ```

3. Check web logs:
   ```bash
   docker-compose logs web
   ```

### Relay Not Processing Notifications

1. Ensure the web application has been accessed at least once (to initialize the database)

2. Check relay logs:
   ```bash
   docker-compose logs relay
   ```

3. Verify relay characters are properly configured in the web interface

## Security Considerations

For production deployments:

1. **Change default passwords**: Update `DB_ROOT_PASSWORD` and `DB_PASSWORD` in `.env`
2. **Use HTTPS**: Set up a reverse proxy (nginx/Apache) with SSL certificates
3. **Restrict database access**: Don't expose the database port publicly
4. **Secure environment file**: Set proper permissions on `.env`:
   ```bash
   chmod 600 .env
   ```
5. **Regular updates**: Keep the application and Docker images updated

## Additional Resources

- [Eve Watchman README](README.md)
- [Configuration Reference](config/config.ini.dist)
- [Eve Online Developers](https://developers.eveonline.com/)
