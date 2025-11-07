#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() { echo -e "${YELLOW}⏳ $1...${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Check if curl is installed
check_curl() {
    if ! command -v curl &>/dev/null; then
        print_error "curl is not installed"
        print_status "Installing curl..."
        if command -v apt-get &>/dev/null; then
            sudo apt-get update && sudo apt-get install -y curl
        elif command -v yum &>/dev/null; then
            sudo yum install -y curl
        else
            print_error "Could not install curl automatically"
            exit 1
        fi
        print_success "curl installed"
    fi
}

# Function to run remote scripts
run_remote_script() {
    local url=$1
    local script_name=$(basename "$url")
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Running: $script_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    check_curl
    local temp_script=$(mktemp)
    print_status "Downloading script"

    if curl -fsSL "$url" -o "$temp_script"; then
        print_success "Download successful"
        chmod +x "$temp_script"
        bash "$temp_script"
        rm -f "$temp_script"
    else
        print_error "Failed to download script"
    fi

    echo ""
    read -p "$(echo -e "${YELLOW}Press Enter to continue...${NC}")" -n 1
}

# Function to show system info
system_info() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}          SYSTEM INFORMATION${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    echo -e "• ${GREEN}Hostname:${NC} $(hostname)"
    echo -e "• ${GREEN}User:${NC} $(whoami)"
    echo -e "• ${GREEN}System:${NC} $(uname -srm)"
    echo -e "• ${GREEN}Uptime:${NC} $(uptime -p | sed 's/up //')"
    echo -e "• ${GREEN}Memory:${NC} $(free -h | awk '/Mem:/ {print $3"/"$2}')"
    echo -e "• ${GREEN}Disk:${NC} $(df -h / | awk 'NR==2 {print $3"/"$2 " ("$5")"}')"

    echo ""
    read -p "$(echo -e "${YELLOW}Press Enter to continue...${NC}")" -n 1
}

# Function to show detailed disk info
disk_info() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}          DETAILED DISK INFORMATION${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    echo -e "${YELLOW}Disk Usage:${NC}"
    df -h | grep -v tmpfs
    
    echo -e "\n${YELLOW}Largest Directories in /:${NC}"
    sudo du -h --max-depth=1 / 2>/dev/null | sort -hr | head -n 10
    
    echo -e "\n${YELLOW}Disk Partitions:${NC}"
    lsblk
    
    echo -e "\n${YELLOW}IO Stats:${NC}"
    iostat -x 1 1 2>/dev/null || echo "iostat not available"

    echo ""
    read -p "$(echo -e "${YELLOW}Press Enter to continue...${NC}")" -n 1
}

# Function to display the main menu
show_menu() {
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}         JISHNU HOSTING MANAGER${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    echo -e " 1) ${BLUE}Panel Installation${NC}"
    echo -e " 2) ${BLUE}Wings Installation${NC}"
    echo -e " 3) ${BLUE}Panel Update${NC}"
    echo -e " 4) ${BLUE}Uninstall Tools${NC}"
    echo -e " 5) ${BLUE}Blueprint Setup${NC}"
    echo -e " 6) ${BLUE}Cloudflare Setup${NC}"
    echo -e " 7) ${BLUE}Change Theme${NC}"
    echo -e " 8) ${BLUE}System Information${NC}"
    echo -e " 9) ${BLUE}Tailscale${NC}"
    echo -e "10) ${BLUE}Database Setup${NC}"
    echo -e "11) ${BLUE}System Disk Info${NC}"
    echo -e "12) ${BLUE}DeathSpider Script${NC}"
    echo -e "13) ${BLUE}VPS Install${NC}"
    echo -e " 0) ${RED}Exit${NC}"

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Select an option [0-13]: ${NC}"
}

# Database setup function
database_setup() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}          DATABASE SETUP${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    read -p "Enter database username: " DB_USER
    read -sp "Enter password: " DB_PASS
    echo ""
    
    echo -e "${YELLOW}Creating database user...${NC}"
    mysql -u root -p <<MYSQL_SCRIPT
CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

    echo -e "${GREEN}Database user '$DB_USER' created!${NC}"
    echo ""
    read -p "$(echo -e "${YELLOW}Press Enter to continue...${NC}")" -n 1
}

# Tailscale setup
tailscale_setup() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}          TAILSCALE SETUP${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    check_curl

    if curl -fsSL https://tailscale.com/install.sh | sh; then
        print_success "Tailscale installed"
        sudo tailscale up
    else
        print_error "Tailscale installation failed"
    fi

    echo ""
    read -p "$(echo -e "${YELLOW}Press Enter to continue...${NC}")" -n 1
}

# Main loop
while true; do
    show_menu
    read -r choice

    case $choice in
        1) run_remote_script "https://raw.githubusercontent.com/gyantst04/og/refs/heads/main/panel.sh" ;;
        2) run_remote_script "https://raw.githubusercontent.com/gyantst04/og/refs/heads/main/wing.sh" ;;
        3) run_remote_script "https://raw.githubusercontent.com/gyantst04/og/refs/heads/main/update.sh" ;;
        4) run_remote_script "https://raw.githubusercontent.com/gyantst04/og/refs/heads/main/uninstall.sh" ;;
        5) run_remote_script "https://raw.githubusercontent.com/gyantst04/og/refs/heads/main/blueprint.sh" ;;
        6) run_remote_script "https://raw.githubusercontent.com/gyantst04/og/refs/heads/main/cf.sh" ;;
        7) run_remote_script "https://raw.githubusercontent.com/gyantst04/og/refs/heads/main/theme.sh" ;;
        8) system_info ;;
        9) tailscale_setup ;;
        10) database_setup ;;
        11) disk_info ;;
        12) run_remote_script "https://raw.githubusercontent.com/gyantst04/DeathSpider/refs/heads/main/7.sh" ;;
        13) run_remote_script "https://raw.githubusercontent.com/gyantst04/og/refs/heads/main/ivps.sh" ;;
        0)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            print_error "Invalid option!"
            sleep 1
            ;;
    esac
done
