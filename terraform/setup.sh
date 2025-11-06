#!/bin/bash

# CyberLab Terraform Setup Script
# Automates initial setup and validation

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Functions
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

check_command() {
    if command -v $1 &> /dev/null; then
        print_success "$1 is installed"
        return 0
    else
        print_error "$1 is not installed"
        return 1
    fi
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "darwin"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Main setup
main() {
    print_header "CyberLab Terraform Setup"

    # Detect OS
    OS=$(detect_os)
    echo -e "Detected OS: ${GREEN}$OS${NC}\n"

    # Check prerequisites
    print_header "Checking Prerequisites"

    MISSING_TOOLS=()

    if ! check_command terraform; then
        MISSING_TOOLS+=("terraform")
    fi

    if ! check_command docker; then
        MISSING_TOOLS+=("docker")
    fi

    # Check for hypervisor
    HAS_HYPERVISOR=false

    if [[ "$OS" == "darwin" ]]; then
        if check_command vmrun; then
            print_success "VMware Fusion detected"
            HAS_HYPERVISOR=true
            RECOMMENDED_HYPERVISOR="fusion"
        fi
    elif [[ "$OS" == "linux" ]] || [[ "$OS" == "windows" ]]; then
        if check_command vmrun; then
            print_success "VMware Workstation detected"
            HAS_HYPERVISOR=true
            RECOMMENDED_HYPERVISOR="vmware"
        fi
    fi

    if command -v VBoxManage &> /dev/null; then
        print_success "VirtualBox detected"
        HAS_HYPERVISOR=true
        if [[ -z "$RECOMMENDED_HYPERVISOR" ]]; then
            RECOMMENDED_HYPERVISOR="virtualbox"
        fi
    fi

    if [[ "$HAS_HYPERVISOR" == false ]]; then
        print_warning "No hypervisor detected (optional for Docker-only deployment)"
    fi

    # Report missing tools
    if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
        echo ""
        print_error "Missing required tools:"
        for tool in "${MISSING_TOOLS[@]}"; do
            echo "  - $tool"
        done
        echo ""
        echo "Install instructions:"
        if [[ "$OS" == "darwin" ]]; then
            echo "  brew install terraform docker"
        elif [[ "$OS" == "linux" ]]; then
            echo "  See README.md for installation instructions"
        fi
        exit 1
    fi

    # Create necessary directories
    print_header "Creating Directories"
    mkdir -p iso backups logs
    print_success "Directories created"

    # Check for existing configuration
    print_header "Configuration Setup"

    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found"
        echo ""
        read -p "Would you like to create terraform.tfvars from template? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cp terraform.tfvars.example terraform.tfvars

            # Auto-configure based on detected environment
            if [[ -n "$RECOMMENDED_HYPERVISOR" ]]; then
                sed -i.bak "s/hypervisor = \"fusion\"/hypervisor = \"$RECOMMENDED_HYPERVISOR\"/" terraform.tfvars
                rm terraform.tfvars.bak 2>/dev/null || true
            fi

            if [[ "$OS" == "darwin" ]]; then
                sed -i.bak 's/platform = "darwin"/platform = "darwin"/' terraform.tfvars
            elif [[ "$OS" == "linux" ]]; then
                sed -i.bak 's/platform = "darwin"/platform = "linux"/' terraform.tfvars
            elif [[ "$OS" == "windows" ]]; then
                sed -i.bak 's/platform = "darwin"/platform = "windows"/' terraform.tfvars
            fi

            rm terraform.tfvars.bak 2>/dev/null || true

            print_success "terraform.tfvars created"
            print_warning "Review and update terraform.tfvars with your settings"
        else
            print_warning "Skipping terraform.tfvars creation"
        fi
    else
        print_success "terraform.tfvars already exists"
    fi

    # Validate Docker
    print_header "Validating Docker"
    if docker ps &> /dev/null; then
        print_success "Docker is running"

        # Check for conflicting networks
        if docker network ls | grep -q "cyberlab"; then
            print_warning "Existing CyberLab networks found"
            echo ""
            read -p "Remove existing networks? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                docker network ls --filter "name=cyberlab" -q | xargs -r docker network rm
                print_success "Networks removed"
            fi
        fi
    else
        print_error "Docker is not running. Start Docker Desktop and try again."
        exit 1
    fi

    # Initialize Terraform
    print_header "Initializing Terraform"

    if terraform init; then
        print_success "Terraform initialized successfully"
    else
        print_error "Terraform initialization failed"
        exit 1
    fi

    # Validate configuration
    print_header "Validating Configuration"

    if terraform validate; then
        print_success "Configuration is valid"
    else
        print_error "Configuration validation failed"
        exit 1
    fi

    # Summary
    print_header "Setup Complete"
    echo ""
    echo -e "${GREEN}✓ All prerequisites met${NC}"
    echo -e "${GREEN}✓ Directories created${NC}"
    echo -e "${GREEN}✓ Terraform initialized${NC}"
    echo -e "${GREEN}✓ Configuration validated${NC}"
    echo ""

    echo -e "${BLUE}Detected Configuration:${NC}"
    echo "  OS: $OS"
    echo "  Hypervisor: ${RECOMMENDED_HYPERVISOR:-none (Docker-only)}"
    echo ""

    echo -e "${BLUE}Next Steps:${NC}"
    echo "  1. Review terraform.tfvars and update as needed"
    echo "  2. Run: terraform plan"
    echo "  3. Run: terraform apply"
    echo ""
    echo "Or use the Makefile:"
    echo "  make plan      # Review changes"
    echo "  make apply     # Deploy infrastructure"
    echo "  make status    # Check deployment status"
    echo ""
    echo -e "${GREEN}For help: make help${NC}"
}

# Run main function
main
