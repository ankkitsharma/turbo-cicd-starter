# Deployment Guide

This guide explains how to deploy your Turbo CI Starter monorepo to a VPS using Docker, Docker Compose, and GitHub Actions.

## Architecture

- **API**: Express.js backend running on port 3001
- **Web**: React frontend with Vite running on port 3000 (served via Nginx)
- **Database**: Not included (add your database service as needed)

## Prerequisites

- VPS with Ubuntu 20.04+ or similar Linux distribution
- Domain name (optional, for SSL)
- GitHub repository with Actions enabled

## VPS Setup

### 1. Initial Server Setup

Run the setup script on your VPS as root:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/scripts/setup-vps.sh | bash
```

Or manually:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add user to docker group
sudo usermod -aG docker $USER
```

### 2. Configure SSH Access

Add your SSH public key to the server:

```bash
# On your local machine
ssh-copy-id user@your-vps-ip

# Or manually add to ~/.ssh/authorized_keys
```

### 3. Clone Repository

```bash
cd /opt
sudo git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git turbo-ci-starter
sudo chown -R $USER:$USER turbo-ci-starter
cd turbo-ci-starter
```

## GitHub Actions Configuration

### 1. Repository Secrets

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

- `VPS_HOST`: Your VPS IP address or domain
- `VPS_USERNAME`: SSH username for your VPS
- `VPS_SSH_KEY`: Your private SSH key (the entire key including headers)
- `VPS_PORT`: SSH port (usually 22)
- `GITHUB_TOKEN`: Automatically provided by GitHub
- `GITHUB_USERNAME`: Your GitHub username

### 2. Container Registry

The workflows automatically push images to GitHub Container Registry (`ghcr.io`). Make sure your repository has the necessary permissions.

## Deployment Workflows

### Separate Deployments

The CI/CD is set up with separate workflows for each app:

- **API Changes**: Triggers when files in `apps/api/` or `packages/` change
- **Web Changes**: Triggers when files in `apps/web/` or `packages/` change

### Workflow Files

- `.github/workflows/deploy-api.yml`: Builds and deploys API
- `.github/workflows/deploy-web.yml`: Builds and deploys Web app

## Manual Deployment

### Using Docker Compose

```bash
# Production deployment
docker-compose up -d

# Development deployment
docker-compose -f docker-compose.dev.yml up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Using Deployment Script

```bash
# Set environment variables
export GITHUB_TOKEN="your_github_token"
export GITHUB_USERNAME="your_github_username"

# Run deployment script
./scripts/deploy.sh
```

## Environment Configuration

### Environment Variables

Create `.env` files as needed:

```bash
# .env (root level)
NODE_ENV=production

# apps/api/.env
PORT=3001
DATABASE_URL=your_database_url

# apps/web/.env
VITE_API_URL=http://localhost:3001
```

### Docker Compose Override

For production-specific configurations, create `docker-compose.override.yml`:

```yaml
version: "3.8"

services:
  api:
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}

  web:
    environment:
      - NODE_ENV=production
```

## Monitoring and Maintenance

### Health Checks

Add health checks to your Dockerfiles:

```dockerfile
# In API Dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3001/health || exit 1
```

### Log Management

```bash
# View logs
docker-compose logs -f api
docker-compose logs -f web

# Log rotation (add to crontab)
0 2 * * * docker system prune -f
```

### Backup Strategy

```bash
# Backup volumes (if using any)
docker run --rm -v your_volume:/data -v $(pwd):/backup alpine tar czf /backup/backup.tar.gz /data
```

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure user is in docker group
2. **Port Conflicts**: Check if ports 3000/3001 are available
3. **Build Failures**: Check Dockerfile syntax and dependencies
4. **Deployment Failures**: Verify SSH keys and secrets

### Debug Commands

```bash
# Check Docker status
docker ps
docker-compose ps

# Check logs
docker-compose logs api
docker-compose logs web

# Check system resources
docker stats

# Clean up
docker system prune -a
```

## Security Considerations

1. **Firewall**: Configure UFW or iptables
2. **SSL**: Use Let's Encrypt with Certbot
3. **Updates**: Keep system and Docker updated
4. **Secrets**: Never commit secrets to repository
5. **Access**: Use SSH keys, disable password auth

## Scaling

### Horizontal Scaling

```yaml
# docker-compose.yml
services:
  api:
    deploy:
      replicas: 3

  web:
    deploy:
      replicas: 2
```

### Load Balancing

Use Nginx or Traefik for load balancing multiple instances.

## Support

For issues or questions:

1. Check the logs first
2. Verify configuration
3. Test locally with Docker Compose
4. Check GitHub Actions workflow runs
