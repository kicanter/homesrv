#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Need root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as with sudo${NC}"
    exit 1
fi

# Make sure to rename .env.example to .env and set secrets before running this!
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: `.env` file not found!${NC}"
    echo -e "Remember to rename `.env.example` and add your secrets"
    exit 1
fi

source .env
STACK_DIR="/opt/stacks/${SITE_DOMAIN}"
SITE_DIR="/srv/www/${SITE_DOMAIN}"
REAL_USER=${SUDO_USER:-$USER}

echo -e "${BLUE}Starting infrastructure setup...${NC}"

# Establish system directories
sudo mkdir -p $STACK_DIR/caddy $STACK_DIR/ddclient $STACK_DIR/forgejo/data $SITE_DIR
sudo chown -R $REAL_USER:$REAL_USER $STACK_DIR $SITE_DIR

# Install deps
sudo apt update && sudo apt install -y docker.io docker-compose git ufw fail2ban

# Forgejo passthrough
echo -e "${BLUE}Setting up Forgejo SSH Passthrough...${NC}"
if ! id "git" &>/dev/null; then
    sudo adduser --disabled-password --gecos "" git
fi

echo -e "${BLUE}Adding $REAL_USER to the docker group...${NC}"
if ! groups "$REAL_USER" | grep -q "\bdocker\b"; then
    sudo groupadd -f docker
    sudo usermod -aG docker "$REAL_USER"
    echo -e "${YELLOW}Note: You will need to log out and back in for the 'docker' group to take effect.${NC}"
else
    echo -e "${GREEN}User $REAL_USER is already in the docker group.${NC}"
fi

# Copy config files
echo -e "${BLUE}Copying configuration files...${NC}"
cp configs/forgejo-shell /usr/local/bin/forgejo-shell # Copy the standalone shell file to the system path
chmod +x /usr/local/bin/forgejo-shell
usermod -s /usr/local/bin/forgejo-shell git
cp configs/Caddyfile $STACK_DIR/caddy/Caddyfile
cp configs/ddclient.conf $STACK_DIR/ddclient/ddclient.conf
cp docker-compose.yaml $STACK_DIR/docker-compose.yaml
cp .env $STACK_DIR/.env

# replace placeholders with env vars in ddclient.conf
sed -i "s/PORKBUN_API_KEY_PLACEHOLDER/${PORKBUN_API_KEY}/" $STACK_DIR/ddclient/ddclient.conf
sed -i "s/PORKBUN_SECRET_KEY_PLACEHOLDER/${PORKBUN_SECRET_KEY}/" $STACK_DIR/ddclient/ddclient.conf
sed -i "s/DOMAIN_PLACEHOLDER/${SITE_DOMAIN}/" $STACK_DIR/ddclient/ddclient.conf

echo -e "${BLUE}Hardening SSH...${NC}"
# replace placeholder with env vars in sshd_config
sudo cp configs/sshd_config /etc/ssh/sshd_config
sudo sed -i "s/USER_PLACEHOLDER/$REAL_USER/" /etc/ssh/sshd_config
sudo chmod 644 /etc/ssh/sshd_config
sudo sshd -t && sudo systemctl restart ssh

# Create fail2ban
echo -e "${BLUE}Setting up fail2ban...${NC}"
sudo cp configs/jail.local /etc/fail2ban/jail.local
sudo systemctl restart fail2ban

# Secure host firewall
echo -e "${BLUE}Configuring firewall...${NC}"
sudo ufw allow 80,443,4922,22/tcp
sudo ufw --force enable

echo -e "${GREEN}Site infrastructure setup complete!${NC}"
echo -e -e "Now run \`${BLUE}cd $STACK_DIR && docker-compose up -d${NC}\` to start running the container."
