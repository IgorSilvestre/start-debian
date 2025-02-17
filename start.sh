#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

#####################################################################
# NEW FLOW: NVIDIA FIRST, THEN REST, THEN FLAG
# If script is run a second time (FLAG_FILE present), it installs CUDA and quits.
#####################################################################

FLAG_FILE="/tmp/nvidia_install_flag"

# Step 1: Update/Upgrade packages
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y

# Step 2: If NVIDIA flag file exists, we install CUDA and quit early
if [ -f "$FLAG_FILE" ]; then
    echo "NVIDIA drivers already installed. Installing CUDA Toolkit..."
    sudo apt install -y nvidia-cuda-toolkit
    rm -f "$FLAG_FILE"
echo "CUDA installation complete. Quitting script now."
    exit 0
fi

# Step 3: Check if NVIDIA drivers are installed; if not, install them
if ! dpkg -l | grep -q "nvidia-driver"; then
    echo "NVIDIA driver not found. Installing now..."
    sudo apt install -y nvidia-driver
    echo "NVIDIA driver installation complete."
fi

#####################################################################
# STEP 4: INSTALL BASE DEPENDENCIES / APPLICATIONS
#####################################################################

# Pre-install checks/fixes
sudo groupadd docker || true   # Avoid error if 'docker' group exists

#####################################################################
# GREETINGS AND INFO GATHERING
#####################################################################

figlet "START DEBIAN" | lolcat
echo "---------------------------------------"

echo -e "\nVamo manda bala? Primeiro de tudo me diz seu nome pra gente começar:"  # Using echo -e so \n works.
read varName

echo -e "\nPrazer em te conhecer $varName, vou te explicar como eu funciono, consisto de três partes:\n1. Preciso de umas informações pra ir completando a instalação pra ti, assim tu não precisa ficar voltando aqui pra preencher ;) \n2. Depois disso vou instalar tudo que pode ser feito pelo terminal\n3. Por último te explicar passo-a-passo e fornecer links para as partes que eu não consigo fazer sozinho - nessa parte conto contigo para me ajudar!\nTerminando, vai estar tudo certo e podes começar a trabalhar!\n"

figlet "PARTE 1 - Coletando dados"

gitConfirm=""
while [[ "$gitConfirm" != "s" && "$gitConfirm" != "n" ]]; do
    echo "Você já tem uma conta no GitHub? (s/n)"
    read gitConfirm
done

if [ "$gitConfirm" == "s" ]; then
    echo "Informe seu nome para configuração do Git:"
    read varGitUserName

    echo "Informe seu e-mail para configuração do Git:"
    read varGitUserEmail

    git config --global user.name "$varGitUserName"
    git config --global user.email "$varGitUserEmail"

    # Clone Neovim config repository
    echo "Clonando configuração do Neovim..."
    mkdir -p ~/.config
    cd ~/.config
    git clone git@github.com:IgorSilvestre/nvim-config.git nvim
    cd ~
fi

#####################################################################
# INSTALLING PACKAGES & APPLICATIONS
#####################################################################

figlet "PARTE 2 - Instalando"

# Install Homebrew
figlet "Instalando Homebrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Ensure Homebrew is sourced in .bashrc, .zshrc, and .profile
cat << 'EOF' >> ~/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
EOF

cat << 'EOF' >> ~/.zshrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
EOF

cat << 'EOF' >> ~/.profile
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
EOF

# Reload environment so brew is immediately available
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Install NVM via Brew
figlet "Instalando NVM via Brew"
brew install nvm
mkdir -p ~/.nvm
cat << 'EON' >> ~/.bashrc
export NVM_DIR="$HOME/.nvm"
[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ] && \ . "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"
[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion" ] && \ . "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion"
EON

export NVM_DIR="$HOME/.nvm"
[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ] && \ . "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"
[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion" ] && \ . "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion"

nvm install 20
nvm alias default 20
nvm use 20

# oh-my-zsh
figlet "Instalando oh-my-zsh"
git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
cp -v ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

chsh -s $(which zsh)

# Docker (via Brew)
figlet "Instalando Docker Desktop"

# Official Docker Desktop for Linux on Debian instructions
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg

# Add Docker's GPG key and Docker Desktop apt repo
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-desktop-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-desktop-keyring.gpg] https://download.docker.com/linux/debian docker-desktop main" \
    | sudo tee /etc/apt/sources.list.d/docker-desktop.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-desktop

# Start and enable Docker Desktop in user mode
systemctl --user start docker-desktop
systemctl --user enable docker-desktop

# Docker Desktop version check
docker --version || true

# Docker Desktop installation complete

# Flatpak apps
figlet "Instalando aplicativos essenciais"
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.discordapp.Discord
flatpak install -y flathub com.spotify.Client
flatpak install -y flathub com.vivaldi.Vivaldi
flatpak install -y flathub rest.insomnia

#####################################################################
# FINAL STEP: CREATE NVIDIA FLAG, REBOOT
#####################################################################

# If we've installed or verified the NVIDIA driver, set the flag and reboot
echo "nvidia_driver_installed" > "$FLAG_FILE"

echo "NVIDIA drivers are set. On next run, script will detect the flag and install CUDA."

figlet "FIM"
echo "Reiniciando em 5 segundos para habilitar NVIDIA driver..."
sleep 5
sudo reboot

