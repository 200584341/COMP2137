#!/bin/bash

configure_network() {
    echo "CHECKING NETWORK CONFIGURATION..."
    echo "=================================="

    NETPLAN_FILE="/etc/netplan/00-installer-config.yaml"

    if ! grep -q "192.168.16.21/24" "$NETPLAN_FILE"; then
        echo "Network configuration is not correct. Updating to 192.168.16.21/24..."
        echo "Creating backup of the netplan configuration file..."
        cp "$NETPLAN_FILE" "$NETPLAN_FILE.bak"   # Creating backup of the configuration file

        sudo tee "$NETPLAN_FILE" > /dev/null <<EOT
network:
  version: 2
  ethernets:
    ens0:
      addresses: [192.168.16.21/24]
      nameservers:
        addresses: [192.168.16.2]
EOT

        sudo netplan apply   # Applying the updated network configuration
        echo "Network configuration successfully updated to 192.168.16.21/24."
    else
        echo "Network configuration is already correct."
    fi

    echo ""
}

update_hosts() {
    echo "CHECKING /etc/hosts FILE..."
    echo "=============================="

    if ! grep -q "192.168.16.21 server1" "/etc/hosts"; then
        echo "Updating /etc/hosts to include 192.168.16.21 server1..."
        echo "Creating backup of the /etc/hosts file..."
        cp /etc/hosts /etc/hosts.bak   # Creating backup of the /etc/hosts file

        echo "192.168.16.21 server1" | sudo tee -a /etc/hosts   # Adding entry to /etc/hosts
        echo "/etc/hosts updated with 192.168.16.21 server1."
    else
        echo "/etc/hosts is already correctly configured."
    fi

    echo ""
}

install_software() {
    echo "CHECKING IF APACHE2, SQUID, AND UFW ARE INSTALLED..."
    echo "======================================================="

    if ! dpkg -l | grep -q apache2; then
        echo "Installing Apache2..."
        sudo apt-get update   # Updating package list
        sudo apt-get install -y apache2   # Installing Apache2
    else
        echo "Apache2 is already installed."
    fi

    if ! dpkg -l | grep -q squid; then
        echo "Installing Squid..."
        sudo apt-get install -y squid   # Installing Squid
    else
        echo "Squid is already installed."
    fi

    if ! dpkg -l | grep -q ufw; then
        echo "Installing UFW..."
        sudo apt-get install -y ufw   # Installing UFW
    fi

    echo "Enabling and starting Apache2 and Squid services..."
    sudo systemctl enable apache2 squid   # Enabling services to start on boot
    sudo systemctl start apache2 squid   # Starting Apache2 and Squid services

    echo "Configuring firewall with UFW..."
    sudo ufw --force reset   # Resetting UFW to default
    sudo ufw allow ssh   # Allowing SSH through the firewall
    sudo ufw allow http   # Allowing HTTP through the firewall
    sudo ufw allow from 192.168.16.0/24 to any port 22   # Allowing SSH from specific network
    sudo ufw allow 3128   # Allowing Squid proxy port

    sudo ufw --force enable   # Enabling UFW
    if sudo ufw status | grep -q "Status: active"; then
        echo "Firewall is active and enabled on system startup."
    else
        echo "Failed to activate the firewall."
    fi

    echo "Checking if Apache2 and Squid are running..."
    if systemctl is-active --quiet apache2; then
        echo "Apache2 is running."
    else
        echo "Failed to start Apache2."
    fi

    if systemctl is-active --quiet squid; then
        echo "Squid is running."
    else
        echo "Failed to start Squid."
    fi

    echo ""
}

create_users() {
    echo "CREATING USER ACCOUNTS..."
    echo "=============================="

    USERS=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

    for USER in "${USERS[@]}"; do
        if ! id "$USER" &>/dev/null; then
            echo "Creating user $USER..."
            sudo useradd -m -s /bin/bash "$USER"   # Creating user account
        else
            echo "User $USER already exists."
        fi

        echo "Generating SSH keys for $USER..."
        sudo -u "$USER" bash -c '
            mkdir -p ~/.ssh   # Creating SSH directory
            if [ ! -f ~/.ssh/id_rsa ]; then
                ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ""   # Generating RSA SSH key
                echo "Generated RSA key for $USER"
            fi
            if [ ! -f ~/.ssh/id_ed25519 ]; then
                ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""   # Generating ED25519 SSH key
                echo "Generated ED25519 key for $USER"
            fi
            cat ~/.ssh/*.pub > ~/.ssh/authorized_keys   # Adding public keys to authorized keys
            chmod 700 ~/.ssh   # Setting correct permissions for SSH directory
            chmod 600 ~/.ssh/authorized_keys   # Setting correct permissions for authorized keys
        '

    done

    if ! groups dennis | grep -q "\bsudo\b"; then
        echo "Adding dennis to the sudo group..."
        sudo usermod -aG sudo dennis   # Adding user 'dennis' to sudo group
    else
        echo "dennis already has sudo access."
    fi

    echo "Adding SSH key for dennis..."
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" | sudo tee -a /home/dennis/.ssh/authorized_keys   # Adding SSH key for 'dennis'

    echo ""
    echo ""
}

main() {
    echo ""
    echo "STARTING THE CONFIGURATION SCRIPT..."
    echo "====================================="
    echo ""

    configure_network   # Calling the network configuration function
    update_hosts   # Calling the update hosts function
    install_software   # Calling the install software function
    create_users   # Calling the create users function

    echo "USERS ARE CREATED AND CONFIGURATION IS COMPLETED!!"
    echo ""
}

main   # Running the main function

