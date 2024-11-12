#!/bin/bash

# Function to print section headers
print_header() {
    echo -e "\n\033[1;34m==== $1 ====\033[0m"  # Print a bold header in blue
}

# Function to print success messages
print_success() {
    echo -e "\033[0;32m$1\033[0m"  # Print success messages in green
}

# Function to print error messages
print_error() {
    echo -e "\033[0;31mERROR: $1\033[0m"  # Print error messages in red
}

# Configure network interface
configure_network() {
    print_header "Configuring Network Interface"  # Display section header for network config
    
    # Check if the network interface is already configured correctly
    if grep -q "192.168.16.21/24" /etc/netplan/01-netcfg.yaml; then  # Check if IP address is already set
        print_success "Network interface already configured correctly."  # Network is already configured
    else
        # Backup the current network configuration
        cp /etc/netplan/01-netcfg.yaml /etc/netplan/01-netcfg.yaml.bak  # Create a backup of the current config
        
        # Update the netplan configuration with the new IP address and settings
        cat << EOF > /etc/netplan/01-netcfg.yaml  # Write new network config to the file
network:
  version: 2
  renderer: networkd
  ethernets:
    ens3:
      addresses:
        - 192.168.16.21/24  # Set static IP address
      gateway4: 192.168.16.2  # Set gateway IP
      nameservers:
        addresses: [192.168.16.2]  # Set DNS server
EOF
        
        # Apply the new network settings
        netplan apply  # Apply new network configuration
        
        # Check if the command was successful
        if [ $? -eq 0 ]; then  # $? checks the exit status of the previous command
            print_success "Network interface configured successfully."  # Success message
        else
            print_error "Failed to configure network interface."  # Error message
        fi
    fi
}

# Update /etc/hosts file
update_hosts_file() {
    print_header "Updating /etc/hosts File"  # Display section header for hosts file update
    
    # Check if the correct IP address and hostname are already in the hosts file
    if grep -q "192.168.16.21.*server1" /etc/hosts; then  # Check if the right entry exists
        print_success "/etc/hosts file already contains the correct entry."  # Entry is correct
    else
        # Remove any existing entries for server1
        sed -i '/.*server1/d' /etc/hosts  # Delete lines containing 'server1'
        
        # Add the new correct entry to the hosts file
        echo "192.168.16.21 server1" >> /etc/hosts  # Add IP address and hostname
        
        print_success "Updated /etc/hosts file."  # Success message
    fi
}

# Install and configure software
install_software() {
    print_header "Installing and Configuring Software"  # Display section header for software installation
    
    # Update the list of available packages
    apt update  # Update the package list
    
    # Install Apache2 if not already installed
    if ! dpkg -s apache2 >/dev/null 2>&1; then  # Check if Apache2 is installed
        apt install -y apache2  # Install Apache2
        print_success "Apache2 installed."  # Success message
    else
        print_success "Apache2 is already installed."  # Apache2 is already installed
    fi
    
    # Install Squid if not already installed
    if ! dpkg -s squid >/dev/null 2>&1; then  # Check if Squid is installed
        apt install -y squid  # Install Squid
        print_success "Squid installed."  # Success message
    else
        print_success "Squid is already installed."  # Squid is already installed
    fi
    
    # Ensure the Apache2 and Squid services are running
    systemctl enable --now apache2  # Start Apache2 service
    systemctl enable --now squid  # Start Squid service
    
    print_success "Apache2 and Squid services are running."  # Success message
}

# Create user accounts
create_users() {
    print_header "Creating User Accounts"  # Display section header for user account creation
    
    # List of users to create
    users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
    
    # Loop through each user in the list
    for user in "${users[@]}"; do
        if id "$user" >/dev/null 2>&1; then  # Check if user already exists
            print_success "User $user already exists."  # User already exists
        else
            useradd -m -s /bin/bash "$user"  # Create user with home directory and bash shell
            print_success "Created user $user."  # Success message
        fi
        
        # Generate SSH keys for the user if not already created
        if [ ! -f "/home/$user/.ssh/id_rsa" ]; then  # Check if RSA key exists
            su - "$user" -c "ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa"  # Generate RSA key
            print_success "Generated RSA key for $user."  # Success message
        fi
        
        if [ ! -f "/home/$user/.ssh/id_ed25519" ]; then  # Check if ED25519 key exists
            su - "$user" -c "ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519"  # Generate ED25519 key
            print_success "Generated ED25519 key for $user."  # Success message
        fi
        
        # Add both public keys to the authorized_keys file
        su - "$user" -c "cat ~/.ssh/id_rsa.pub ~/.ssh/id_ed25519.pub > ~/.ssh/authorized_keys"  # Add keys
        print_success "Added public keys to authorized_keys for $user."  # Success message
    done
    
    # Add dennis to the sudo group
    usermod -aG sudo dennis  # Add user dennis to sudo group
    print_success "Added dennis to sudo group."  # Success message
    
    # Add the specified public key for dennis
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" >> /home/dennis/.ssh/authorized_keys  # Add specific key for dennis
    print_success "Added specified public key for dennis."  # Success message
}

# Main execution
main() {
    if [ "$EUID" -ne 0 ]; then  # Check if the script is run as root
        print_error "This script must be run as root."  # Error message if not root
        exit 1  # Exit with error
    fi
    
    configure_network  # Call function to configure network
    update_hosts_file  # Call function to update hosts file
    install_software  # Call function to install software
    create_users  # Call function to create user accounts
    
    print_header "Configuration Complete"  # Final header
    print_success "The server has been configured according to the specifications."  # Success message
}

main  # Run the main function
