#!/bin/bash

# Starting the report with a blank line for readability
echo ""                           # Adding a blank line for clarity

# Generating report header with username and current date/time
echo "System Report generated by $(whoami), $(date)"  # Creating the report header with user info and date

# Displaying System Information Section
echo -e "\nSystem Information"          # Starting the System Information section
echo "------------------"                # Creating a line for separation
hostname=$(hostname)                    # Getting the hostname
os=$(grep "^NAME=" /etc/os-release | cut -d '=' -f2 | tr -d '"') # Getting OS name
version=$(grep "^VERSION=" /etc/os-release | cut -d '=' -f2 | tr -d '"') # Getting OS version 
uptime=$(uptime -p)                    # Getting the system uptime

# Displaying system information
echo "Hostname: $hostname"              # Showing the hostname
echo "OS: $os $version"                 # Showing the OS name and version
echo "Uptime: $uptime"                  # Showing how long the system has been running

# Displaying Hardware Information Section
echo -e "\nHardware Information"         # Starting the Hardware Information section
echo "--------------------"               # Creating a line for separation
cpu=$(lscpu | grep "Model name" | cut -d ':' -f2 | xargs) # Getting CPU make and model
current_speed=$(grep "cpu MHz" /proc/cpuinfo | awk 'NR==1{print $4}') # Getting current CPU speed
max_speed=$(sudo dmidecode -t processor | grep -m 1 "Max Speed" | awk '{print $3 " " $4}') # Getting maximum CPU speed
ram=$(free -h --si | grep "Mem:" | awk '{print $2 " GiB"}') # Getting installed RAM size with GiB
disks=$(lsblk -d -o NAME,SIZE,MODEL | tail -n +2 | awk '{print "- " $3 ": " $2}') # Getting disk make, model, and size formatted
video=$(lspci | grep -i vga | cut -d ':' -f3 | xargs) # Getting video card make and model

# Displaying hardware information with combined CPU speed
echo "CPU: $cpu"                        # Showing CPU make and model
echo "Speed: $current_speed MHz (Max: $max_speed)"  # Showing current and maximum CPU speed
echo "RAM: $ram"                        # Showing total RAM size
echo -e "Disk(s):\n$disks"              # Showing disk information
echo "Video: $video"                    # Showing video card information

# Displaying Network Information Section
echo -e "\nNetwork Information"          # Starting the Network Information section
echo "-------------------"                # Creating a line for separation

# Getting Fully Qualified Domain Name
fqdn=$(hostname -f)                     # Getting the Fully Qualified Domain Name

# Getting host IP address
host_ip=$(hostname -I | awk '{print $1}') # Getting the primary IP address

# Getting gateway IP
gateway_ip=$(ip route | grep default | awk '{print $3}') # Getting the default gateway IP

# Getting DNS server IP
dns_server=$(grep -m1 '^nameserver ' /etc/resolv.conf | awk '{print $2}') # Getting the DNS server IP

# Getting the primary network interface
interface=$(ip link show | awk -F ': ' '/^[0-9]+:/{print $2}' | grep -E 'ens[0-9]+' | head -n 1) # Getting the primary network interface

# Getting the make and model of the network card, suppressing warnings
make_model=$(sudo lshw -C network 2>/dev/null | awk -F 'product: ' '/product/{print $2; exit}' | xargs) # Getting network card make and model

# Getting IP address of the primary network interface in CIDR format
ip_address=$(ip addr show $interface | grep 'inet ' | awk '{print $2}') # Getting the IP address of the interface

# Displaying network information in the desired format
echo "FQDN: $fqdn"                       # Showing Fully Qualified Domain Name
echo "Host Address: $host_ip"            # Showing host IP address
echo "Gateway IP: $gateway_ip"           # Showing gateway IP address
echo "DNS Server: $dns_server"           # Showing DNS server IP
echo ""                                  # Adding a blank line for separation
echo "InterfaceName: $make_model"        # Showing the network interface name and model
echo "IP Address: $ip_address"           # Showing the IP address in CIDR format

# Displaying System Status Section
echo -e "\nSystem Status"                 # Starting the System Status section
echo "-------------"                       # Creating a line for separation

# Getting users logged in using 'who'
users_logged_in=$(who | awk '{print $1}' | sort | uniq | paste -sd ', ') # Getting logged-in users and formatting them

# Getting disk space for local filesystems in a table format without extra header
disk_space=$(df -h --local | awk 'NR==1{header=$0; next} {printf "%-15s %-10s %-10s %-10s %-10s %-10s\n", $1, $2, $3, $4, $5, $6}') # Getting disk space info

# Getting process count
process_count=$(ps aux | wc -l)         # Counting the number of processes

# Getting load averages
load_averages=$(cat /proc/loadavg | awk '{print $1 ", " $2 ", " $3}') # Getting load averages

# Getting memory allocation using free command
memory_allocation=$(free -h)             # Getting memory allocation details

# Getting count of listening network ports and removing leading comma
listening_ports=$(ss -tuln | awk 'NR>1 {print $5}' | cut -d':' -f2 | sort -n | uniq | paste -sd ',' - | sed 's/^,//') # Getting listening ports

# Getting UFW rules
rules=$(sudo ufw status | awk 'NR>2 && !/^(To|From|--)/ && !/\(v6\)/ {print $1, $2}' | paste -sd ',' - | sed 's/,$//') # Getting UFW rules

# Displaying system status information in the desired format
echo "Users Logged In: $users_logged_in" # Showing logged-in users

# Display disk space in table format without extra header
echo -e "Disk Space:"                      # Starting the Disk Space section
echo -e "Filesystem      Size       Used       Available  Use%       Mounted on" # Creating headers for disk space
echo -e "$disk_space"                      # Displaying disk space information

echo "Process Count: $process_count"      # Showing the count of processes
echo "Load Averages: $load_averages"      # Showing load averages

# Display memory allocation
echo -e "Memory Allocation:\n$memory_allocation" # Showing memory allocation details

echo "Listening Network Ports: $listening_ports" # Showing listening network ports
echo "UFW Rules: $rules"                    # Showing UFW rules

# Ending the report with a blank line for readability
echo ""                                   # Adding a blank line for clarity

