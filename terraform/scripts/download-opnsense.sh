#!/bin/bash

# Download and prepare OPNsense ISO for Terraform deployment
# This script downloads the latest OPNsense ISO and prepares it for VirtualBox

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Configuration
OPNSENSE_VERSION="${1:-24.1}"
ISO_DIR="../iso"
ISO_FILE="OPNsense-${OPNSENSE_VERSION}-dvd-amd64.iso"
ISO_BZ2="${ISO_FILE}.bz2"
DOWNLOAD_URL="https://mirror.ams1.nl.leaseweb.net/opnsense/releases/${OPNSENSE_VERSION}/${ISO_BZ2}"
CHECKSUM_URL="https://mirror.ams1.nl.leaseweb.net/opnsense/releases/${OPNSENSE_VERSION}/OPNsense-${OPNSENSE_VERSION}-checksums-amd64.sha256"

print_header "OPNsense ISO Download and Preparation"

# Create ISO directory
mkdir -p "$ISO_DIR"
cd "$ISO_DIR"

# Check if ISO already exists
if [ -f "$ISO_FILE" ]; then
    print_warning "ISO file already exists: $ISO_FILE"
    read -p "Do you want to re-download? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_success "Using existing ISO"
        exit 0
    fi
    rm -f "$ISO_FILE" "$ISO_BZ2"
fi

# Download ISO
print_header "Downloading OPNsense ${OPNSENSE_VERSION}"
echo "URL: $DOWNLOAD_URL"
echo "Size: ~650MB (compressed)"
echo ""

if command -v curl &> /dev/null; then
    curl -L -o "$ISO_BZ2" "$DOWNLOAD_URL" --progress-bar
elif command -v wget &> /dev/null; then
    wget -O "$ISO_BZ2" "$DOWNLOAD_URL" --show-progress
else
    print_error "Neither curl nor wget found. Please install one of them."
    exit 1
fi

if [ $? -eq 0 ]; then
    print_success "Download complete"
else
    print_error "Download failed"
    exit 1
fi

# Download checksums (optional, for verification)
print_header "Downloading Checksums"
if command -v curl &> /dev/null; then
    curl -L -o "checksums.sha256" "$CHECKSUM_URL" 2>/dev/null || print_warning "Checksum download failed (optional)"
elif command -v wget &> /dev/null; then
    wget -O "checksums.sha256" "$CHECKSUM_URL" 2>/dev/null || print_warning "Checksum download failed (optional)"
fi

# Decompress ISO
print_header "Decompressing ISO"
echo "This may take a few minutes..."

if command -v bunzip2 &> /dev/null; then
    bunzip2 -v "$ISO_BZ2"
    print_success "Decompression complete"
elif command -v bzip2 &> /dev/null; then
    bzip2 -d -v "$ISO_BZ2"
    print_success "Decompression complete"
else
    print_error "bzip2 not found. Please install it:"
    echo "  macOS: brew install bzip2"
    echo "  Ubuntu: sudo apt-get install bzip2"
    echo "  CentOS: sudo yum install bzip2"
    exit 1
fi

# Verify ISO exists
if [ ! -f "$ISO_FILE" ]; then
    print_error "ISO file not found after decompression"
    exit 1
fi

# Get ISO size
ISO_SIZE=$(du -h "$ISO_FILE" | cut -f1)
print_success "ISO ready: $ISO_FILE ($ISO_SIZE)"

# Summary
print_header "Setup Complete"
echo ""
echo -e "${GREEN}OPNsense ISO is ready for deployment${NC}"
echo ""
echo "ISO Location: $(pwd)/$ISO_FILE"
echo "ISO Size: $ISO_SIZE"
echo ""
echo "Next steps:"
echo "  1. Update terraform.tfvars:"
echo "     deploy_opnsense = true"
echo "     deploy_architecture = true"
echo ""
echo "  2. Deploy with Terraform:"
echo "     cd .."
echo "     terraform apply"
echo ""
echo "  3. Access OPNsense web UI after boot:"
echo "     https://172.25.40.1"
echo "     Username: root"
echo "     Password: opnsense"
echo ""
print_warning "IMPORTANT: Change default password after first login!"
