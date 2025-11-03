#!/bin/bash
# Update all Docker containers

set -e

echo "=================================================="
echo "Updating All Containers"
echo "=================================================="

# Pull latest images
echo "[*] Pulling latest images..."
docker-compose pull

# Recreate containers with new images
echo "[*] Recreating containers..."
docker-compose up -d --remove-orphans

# Clean up old images
echo "[*] Cleaning up old images..."
docker image prune -f

echo ""
echo "✅ All containers updated successfully!"
echo ""
echo "Container status:"
docker-compose ps
