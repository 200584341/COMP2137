#!/bin/bash

configure_network() {  # Defining function to configure network settings
    echo "CHECKING NETWORK CONFIGURATION..."  # Displaying network configuration check message
    echo "=================================="

    NETPLAN_FILE="/etc/netplan/00-installer-config.yaml"  # Setting path to the netplan configuration file

    if ! grep -q "192.168.16.21/24" "$NETPLAN_FILE"; then  # Checking if network configuration needs updating
        echo "Network configuration is not correct. Updating to 192.168.16.21/24..."  # Displaying update message
        echo "Creating backup of the netplan configuration file..."  # Informing backup creation
        cp "$NETPLAN_FILE" "$NETPLAN_FILE.bak"  # Creating backup of the current netplan configuration file

        sudo tee "$NETPLAN_FILE" > /dev/null <<EOT  # Writing new network configuration
network:
  version: 2
  ethernets:
    ens0:
      addresses: [192.168.16.21/24]
      nameservers:
        addresses: [192.168.16.2]
EOT

        sudo netplan apply  # Applying the new network configuration
        echo "Network configuration successfully updated to 192.168.16.21/24."  # Confirmation message
    else
        echo "Network configuration is already correct."  # Displaying already correct message
    fi

    echo ""
}

update_hosts() {  # Defining function to update /etc/hosts file
    echo "CHECKING /etc/hosts FILE..."  # Displaying /etc/hosts check message
    echo "=============================="

    if ! grep -q "192.168.16.21 server1" "/etc/hosts"; then  # Checking if /etc/hosts needs updating
        echo "Updating /etc/hosts to include 192.168.16.21 server1..."  # Displaying update message
        echo "Creating backup of the /etc/hosts file..."  # Informing backup creation
        cp /etc/hosts /etc/hosts.bak  # Creating backup of /etc/hosts

        echo "192.168.16.21 server1" | sudo tee -a /etc/hosts  # Adding entry to /etc/hosts
        echo "/etc/hosts updated with 192.168.16.21 server1."  # Confirmation message
    else
        echo "/etc/hosts is already correctly configured."  # Displaying already correct message
    fi

    echo ""
}

install_software() {  # Defining function to check and install required software
    echo "CHECKING IF APACHE2, SQUID, AND UFW ARE INSTALLED..."  # Displaying software check message
    echo "======================================================="

    if ! dpkg -l | grep -q apache2; then  # Checking if Apache2 is installed
        echo "Installing Apache2..."  # Displaying installation message
        sudo apt-get update  # Updating package list
        sudo apt-get install -y apache2  # Installing Apache2
    else
        echo "Apache2 is already installed."  # Displaying already installed message
    fi

    if ! dpkg -l | grep -q squid; then  # Checking if Squid is installed
        echo "Installing Squid..."  # Displaying installation message
        sudo apt-get install -y squid  # Installing Squid
    else
        echo "Squid is already installed."  # Displaying already installed message
    fi

    if ! dpkg -l | grep -q ufw; then  # Checking if UFW is installed
        echo "Installing UFW..."  # Displaying installation message
        sudo apt-get install -y ufw  # Installing UFW
    fi

    echo "Enabling and starting Apache2 and Squid services..."  # Displaying service start message
    sudo systemctl enable apache2 squid  # Enabling services to start on boot
    sudo systemctl start apache2 squid  # Starting Apache2 and Squid services

    echo "Configuring firewall with UFW..."  # Displaying firewall configuration message
    sudo ufw --force reset  # Resetting UFW to default
    sudo ufw allow ssh  # Allowing SSH through the firewall
    sudo ufw allow http  # Allowing HTTP through the firewall
    sudo ufw allow from 192.168.16.0/24 to any port 22  # Allowing SSH from specific network
    sudo ufw allow 3128  # Allowing Squid proxy port

    sudo ufw --force enable  # Enabling UFW
    if sudo ufw status | grep -q "Status: active"; then  # Checking if firewall is active
        echo "Firewall is active and enabled on system startup."  # Confirmation message
    else
        echo "Failed to activate the firewall."  # Error message if activation failed
    fi

    echo "Checking if Apache2 and Squid are running..."  # Displaying service check message
    if systemctl is-active --quiet apache2; then  # Checking if Apache2 is running
        echo "Apache2 is running."  # Confirmation message for Apache2
    else
        echo "Failed to start Apache2."  # Error message for Apache2
    fi

    if systemctl is-active --quiet squid; then  # Checking if Squid is running
        echo "Squid is running."  # Confirmation message for Squid
    else
        echo "Failed to start Squid."  # Error message for Squid
    fi

    echo ""
}

create_users() {  # Defining function to create user accounts and configure SSH keys
    echo "CREATING USER ACCOUNTS..."  # Displaying user account creation message
    echo "=============================="

    USERS=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")  # List of users

    for USER in "${USERS[@]}"; do  # Looping through each user
        if ! id "$USER" &>/dev/null; then  # Checking if user exists
            echo "Creating user $USER..."  # Displaying user creation message
            sudo useradd -m -s /bin/bash "$USER"  # Creating user account
        else
            echo "User $USER already exists."  # Displaying already exists message
        fi

        echo "Generating SSH keys for $USER..."  # Displaying SSH key generation message
        sudo -u "$USER" bash -c '  # Running commands as the user
            mkdir -p ~/.ssh  # Creating SSH directory
            if [ ! -f ~/.ssh/id_rsa ]; then  # Checking if RSA key exists
                ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ""  # Generating RSA SSH key
                echo "Generated RSA key for $USER"  # Confirmation message for RSA key
            fi
            if [ ! -f ~/.ssh/id_ed25519 ]; then  # Checking if ED25519 key exists
                ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""  # Generating ED25519 SSH key
                echo "Generated ED25519 key for $USER"  # Confirmation message for ED25519 key
            fi
            cat ~/.ssh/*.pub > ~/.ssh/authorized_keys  # Adding public keys to authorized keys
            chmod 700 ~/.ssh  # Setting permissions for SSH directory
            chmod 600 ~/.ssh/authorized_keys  # Setting permissions for authorized keys
        '

    done

    if ! groups dennis | grep -q "\bsudo\b"; then  # Checking if 'dennis' has sudo access
        echo "Adding dennis to the sudo group..."  # Displaying sudo group addition message
        sudo usermod -aG sudo dennis  # Adding 'dennis' to sudo group
    else
        echo "dennis already has sudo access."  # Displaying already has sudo access message
    fi

    echo "Adding SSH key for dennis..."  # Displaying SSH key addition message for 'dennis'
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" | sudo tee -a /home/dennis/.ssh/authorized_keys  # Adding SSH key for 'dennis'

    echo ""
    echo ""
}

main() {  # Defining main function
    echo ""
    echo "STARTING THE CONFIGURATION SCRIPT..."  # Displaying start message
    echo "====================================="
    echo ""

    configure_network  # Calling the network configuration function
    update_hosts  # Calling the update hosts function
    install_software  # Calling the install software function
    create_users  # Calling the create users function

    echo "USERS ARE CREATED AND CONFIGURATION IS COMPLETED!!"  # Displaying completion message
    echo ""
}

main  # Running the main function

