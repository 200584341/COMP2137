#!/bin/bash

# Exiting on any command failure
set -e                               # Exiting immediately on error

verbose=""                            # Setting verbose mode flag
# Checking and setting verbose mode
if [[ $1 == "-verbose" ]]; then
    verbose="-verbose"               # Enabling verbose mode
fi

# Defining function to log SCP/SSH transfer success
log_transfer() {
    local message="$1"                # Capturing log message
    echo "[INFO] $message" >> lab3.log  # Logging message to lab3.log
    [[ $verbose == "-verbose" ]] && echo "$message"  # Printing to console if verbose
}

# Transferring and running the configuration script on server1
scp -o StrictHostKeyChecking=no configure-host.sh remoteadmin@server1-mgmt:/root && \
log_transfer "Transferred configure-host.sh to server1-mgmt"
ssh -o StrictHostKeyChecking=no remoteadmin@server1-mgmt -- "/root/configure-host.sh -name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4 $verbose" && \
log_transfer "Executed configure-host.sh on server1-mgmt"

# Transferring and running the configuration script on server2
scp -o StrictHostKeyChecking=no configure-host.sh remoteadmin@server2-mgmt:/root && \
log_transfer "Transferred configure-host.sh to server2-mgmt"
ssh -o StrictHostKeyChecking=no remoteadmin@server2-mgmt -- "/root/configure-host.sh -name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3 $verbose" && \
log_transfer "Executed configure-host.sh on server2-mgmt"

# Adding local host entries for loghost and webhost
./configure-host.sh -hostentry loghost 192.168.16.3 && log_transfer "Added local entry for loghost"
./configure-host.sh -hostentry webhost 192.168.16.4 && log_transfer "Added local entry for webhost"
