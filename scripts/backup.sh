#!/bin/bash
# Automated backup script using Restic

set -e

echo "=================================================="
echo "Starting Automated Backup"
echo "=================================================="

# Check if repository is initialized
if ! restic -r "$RESTIC_REPOSITORY" snapshots &>/dev/null; then
    echo "[*] Initializing backup repository..."
    restic -r "$RESTIC_REPOSITORY" init
fi

# Backup function
backup_data() {
    local source=$1
    local tag=$2

    echo "[*] Backing up $tag..."
    restic -r "$RESTIC_REPOSITORY" backup "$source" \
        --tag "$tag" \
        --exclude-file=/backup-source/.restic-exclude \
        --verbose
}

# Create exclude file
cat > /backup-source/.restic-exclude << 'EOF'
*.log
*.tmp
temp/
cache/
*.lock
EOF

# Backup each data source
backup_data "/backup-source/elasticsearch" "elasticsearch"
backup_data "/backup-source/postgres" "postgres"
backup_data "/backup-source/ldap" "ldap"
backup_data "/backup-source/wazuh" "wazuh"
backup_data "/backup-source/configs" "configs"

# Clean up old snapshots (keep last 30 days)
echo "[*] Cleaning up old snapshots..."
restic -r "$RESTIC_REPOSITORY" forget \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 12 \
    --prune

# Check repository integrity
echo "[*] Verifying backup integrity..."
restic -r "$RESTIC_REPOSITORY" check

# Show statistics
echo ""
echo "=================================================="
echo "Backup Statistics"
echo "=================================================="
restic -r "$RESTIC_REPOSITORY" stats

echo ""
echo "✅ Backup completed successfully at $(date)"
