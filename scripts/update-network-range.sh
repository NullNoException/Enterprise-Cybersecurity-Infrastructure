#!/bin/bash
# Update network IP range from 172.20.x.x to 172.25.x.x to avoid conflicts

set -e

echo "=================================================="
echo "Updating Network IP Range"
echo "=================================================="
echo ""
echo "Changing from: 172.20.x.x"
echo "Changing to:   172.25.x.x"
echo ""
echo "This will update:"
echo "  - docker-compose.yml"
echo "  - .env.template"
echo "  - Documentation files"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Aborted."
    exit 1
fi

# Backup files
echo "[*] Creating backups..."
cp docker-compose.yml docker-compose.yml.backup
cp .env.template .env.template.backup
if [ -f .env ]; then
    cp .env .env.backup
fi

# Update docker-compose.yml
echo "[*] Updating docker-compose.yml..."
sed -i.tmp 's/172\.20\./172.25./g' docker-compose.yml
rm -f docker-compose.yml.tmp

# Update .env.template
echo "[*] Updating .env.template..."
sed -i.tmp 's/172\.20\./172.25./g' .env.template
rm -f .env.template.tmp

# Update .env if it exists
if [ -f .env ]; then
    echo "[*] Updating .env..."
    sed -i.tmp 's/172\.20\./172.25./g' .env
    rm -f .env.tmp
fi

# Update documentation
echo "[*] Updating documentation files..."
for file in README.md IMPLEMENTATION_SUMMARY.md docs/*.md; do
    if [ -f "$file" ]; then
        sed -i.tmp 's/172\.20\./172.25./g' "$file"
        rm -f "$file.tmp"
    fi
done

echo ""
echo "=================================================="
echo "✅ Network range updated successfully!"
echo "=================================================="
echo ""
echo "New network configuration:"
echo "  External:   172.25.0.0/24"
echo "  DMZ:        172.25.10.0/24"
echo "  Internal:   172.25.20.0/24"
echo "  Security:   172.25.30.0/24"
echo "  Management: 172.25.40.0/24"
echo ""
echo "Backups saved with .backup extension"
echo ""
echo "Next steps:"
echo "1. Review the changes"
echo "2. Deploy with: docker-compose up -d"
echo ""
