#!/bin/bash
set -euo pipefail

# =======================================
# Rainbow banner for Lapiogamer
# =======================================
rainbow() {
  text=$1
  colors=(31 33 32 36 34 35)
  i=0
  for (( c=0; c<${#text}; c++ )); do
    printf "\033[1;${colors[i]}m${text:$c:1}\033[0m"
    i=$(( (i+1) % ${#colors[@]} ))
  done
  echo
}

clear
rainbow "================================================"
rainbow "    WELCOME TO Lapiogamer Auto Setup"
rainbow "================================================"
echo

# =======================================
# Menu
# =======================================
echo "Choose an option:"
echo "  1) Setup IDX VM (dev.nix + script.sh)"
echo "  2) Run Ubuntu VNC Docker"
echo "  3) Install Pterodactyl Panel + Node"
echo "  4) Install Playit"
echo "  5) Lapio's Custom Dash ChunkDash"
echo "  0) Exit"
echo
read -p "Enter choice: " choice

# =======================================
# Option 1 → create .idx/dev.nix + script.sh
# =======================================
if [ "$choice" = "1" ]; then
  echo "[INFO] Creating .idx folder and dev.nix..."
  mkdir -p "$HOME/.idx"

  cat > "$HOME/.idx/dev.nix" <<'EOF'
{ pkgs, ... }: {
  channel = "stable-24.05";
  packages = [
    pkgs.git
    pkgs.curl
    pkgs.wget
    pkgs.unzip
    pkgs.openssh
    pkgs.sudo
    pkgs.qemu_kvm
    pkgs.cloud-utils
  ];
  env = {
    DEBIAN_FRONTEND = "noninteractive";
  };
  idx = {
    extensions = [
      "ms-vscode.remote-ssh"
      "ms-vscode.cpptools"
      "ms-python.python"
    ];
    workspace = {
      onCreate = {
        setup = ''
          echo "🔄 Preparing lightweight environment..."
          sudo apt-get update -y || true
          echo "✅ Base IDX environment ready"
        '';
      };
      onStart = {
        refresh = ''
          echo "🔁 Refreshing environment..."
          sudo apt-get update -y || true
        '';
      };
    };
    previews = { enable = false; };
  };
}
EOF

  echo "[INFO] Creating script.sh..."
  cat > "$HOME/script.sh" <<'EOF'
#!/bin/bash
set -euo pipefail

clear
cat << "BANNER"
================================================
   ____            _                             
  |  _ \ _ __ ___ | |_ _ __ ___  _ __ ___   __ _ 
  | |_) | '__/ _ \| __| '_ ` _ \| '_ ` _ \ / _` |
  |  __/| | | (_) | |_| | | | | | | | | | | (_| |
  |_|   |_|  \___/ \__|_| |_| |_|_| |_| |_|\__,_|
                                  
   Proxmox VE (Image format safe)
================================================
BANNER

VM_DIR="$HOME/vm"
IMG_FILE="$VM_DIR/proxmox-disk.qcow2"
ISO_FILE="$VM_DIR/proxmox-ve.iso"
MEMORY=4096
CPUS=4
DISK_SIZE=32G

mkdir -p "$VM_DIR"
cd "$VM_DIR"

# Download Proxmox VE installer if not present
if [ ! -f "$ISO_FILE" ]; then
    echo "[INFO] Downloading Proxmox VE installer..."
    wget -q https://download.proxmox.com/iso/proxmox-ve_8.0-2.iso -O "$ISO_FILE"
fi

# Create disk image if not present
if [ ! -f "$IMG_FILE" ]; then
    echo "[INFO] Creating disk image..."
    qemu-img create -f qcow2 "$IMG_FILE" "$DISK_SIZE"
fi

echo "[INFO] Starting Proxmox VE installer..."
KVM_OPTS=""
if [ -e /dev/kvm ]; then
    KVM_OPTS="-enable-kvm -cpu host"
else
    echo "[WARN] KVM not available, running in emulation mode."
    KVM_OPTS="-cpu max"
fi

echo "[INFO] Proxmox VE will start in QEMU."
echo "[INFO] Installation notes:"
echo "  - Disk: $IMG_FILE"
echo "  - RAM: ${MEMORY}MB"
echo "  - CPUs: $CPUS"
echo "  - Boot from ISO to install Proxmox VE"
echo ""
echo "[INFO] Once installed, you can run the VM without ISO to boot Proxmox."

exec qemu-system-x86_64 \
    $KVM_OPTS \
    -m "$MEMORY" \
    -smp "$CPUS" \
    -drive file="$IMG_FILE",format=qcow2,if=virtio \
    -cdrom "$ISO_FILE" \
    -boot order=cd \
    -device virtio-net-pci,netdev=n0 \
    -netdev user,id=n0,hostfwd=tcp::8006-:8006,hostfwd=tcp::22-:22 \
    -vga std \
    -serial mon:stdio
EOF

  chmod +x "$HOME/script.sh"
  echo "[INFO] Running script.sh..."
  bash "$HOME/script.sh"
  
# =======================================
# Option 2 → run Docker Ubuntu VNC
# =======================================
elif [ "$choice" = "2" ]; then
  echo "[INFO] Installing Docker if not present..."
  sudo apt-get update -y
  if ! command -v docker &> /dev/null; then
    sudo apt-get install -y docker.io
    sudo systemctl enable --now docker
    sudo usermod -aG docker $USER
    echo "[INFO] Docker installed and service started."
  else
    echo "[INFO] Docker already installed."
  fi

  docker run -d \
    --name myubuntu \
    -p 6080:6080 \
    -p 5901:5901 \
    -v ubuntu_data:/root \
    lapiogamer/ubuntu-vnc

# =======================================
# Option 3 → Install Pterodactyl Panel + Node
# =======================================
elif [ "$choice" = "3" ]; then
  echo "[INFO] Installing Pterodactyl Panel + Node..."
  bash <(curl -s https://pterodactyl-installer.se)

# =======================================
# Option 4 → Install Playit 
# =======================================
elif [ "$choice" = "4" ]; then
  echo "[INFO] Installing Playit..."
  sudo apt update && sudo apt install -y curl gnupg
  curl -SsL https://playit-cloud.github.io/ppa/key.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/playit.gpg >/dev/null
  echo "deb [signed-by=/etc/apt/trusted.gpg.d/playit.gpg] https://playit-cloud.github.io/ppa/data ./" | sudo tee /etc/apt/sources.list.d/playit-cloud.list
  sudo apt update
  sudo apt install -y playit
  echo "[INFO] Playit VPN installed successfully. You can now run 'playit' command."

# =======================================
# Option 5 → Lapio's Custom Dash ChunkDash
# =======================================
elif [ "$choice" = "5" ]; then
  echo "Lapio's Custom Dash ChunkDash"
  echo "Choose a theme:"
  echo "  1) Feastic Theme"
  echo "  2) Soon"
  echo "  3) Soon"
  echo "  4) Soon"
  echo "  0) Back"
  read -p "Enter theme choice: " theme_choice

  if [ "$theme_choice" = "1" ]; then
    echo "[INFO] You selected Feastic Theme."
    
    # Remove existing folder if exists
    if [ -d "Hosting-panel" ]; then
        rm -rf Hosting-panel
    fi

    # Clone repo first
    git clone https://github.com/deadlauncherg/Hosting-panel.git
    cd Hosting-panel || exit

    # Show message to update settings.json
    echo "⚠️  Make sure to update your settings.json before running (node .)."

    #Run nvm installer
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

    #Run nvm exporter
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    #Run Reload source
    source ~/.bashrc

    #Run nvm cmds
    nvm install 18
    nvm use 18
    nvm alias default 18
    
    #Run verify nvm version
    node -v
    npm -v
    
    #Run apt install sudo
    apt install sudo
    
    #Run sudo apt update
    sudo apt update

    #Run npm install
    npm install

    # Optionally open settings.json (uncomment if needed)
    # nano settings.json

    echo "[INFO] Feastic Theme setup done!"
    echo "Here is your custom banner:"

    # Multi-line ASCII banner
    cat << "BANNER"
  _                _          ____                           
 | |    __ _ _ __ (_) ___    / ___| __ _ _ __ ___   ___ _ __ 
 | |   / _` | '_ \| |/ _ \  | |  _ / _` | '_ ` _ \ / _ \ '__|
 | |__| (_| | |_) | | (_) | | |_| | (_| | | | | | |  __/ |   
 |_____\__,_| .__/|_|\___/   \____|\__,_|_| |_| |_|\___|_|   
            |_|                                              
BANNER

  fi
  
# =======================================
# Exit
# =======================================
else
  echo "[INFO] Exiting..."
  exit 0
fi
