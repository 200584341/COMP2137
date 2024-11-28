#!/bin/bash

# Exiting on any error encountered and ignoring specific signals (TERM, HUP, INT)
set -e                               # Exiting immediately on error
trap '' SIGTERM SIGHUP SIGINT         # Ignoring termination, hangup, and interrupt signals

verbose=0                             # Setting verbose mode to off by default
LOG_FILE="lab3_simulation.log"        # Defining log file to capture output

# Ensuring log file exists
touch "$LOG_FILE"                     # Creating log file if not present

# Logging messages based on verbosity level
log_message() {
    local level="$1"                  # Capturing log level (INFO, WARNING, ERROR)
    shift                             # Shifting to log message
    local msg="$@"                    # Capturing log message
    echo "[$level] $msg" >> "$LOG_FILE"  # Logging message to file
    [[ $verbose -eq 1 ]] && echo "[$level] $msg"  # Displaying message if verbose mode is enabled
}

# Validating IP address format
validate_ip() {
    if [[ ! $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        log_message "ERROR" "Invalid IP address: $1"  # Logging invalid IP format error
        exit 1
    fi
}

# Simulating hostname change
update_hostname() {
    local desiredName="$1"            # Capturing desired hostname
    log_message "INFO" "Simulating hostname change to $desiredName"  # Logging hostname change
    echo "$desiredName" > ./hostname_simulated   # Writing hostname to simulated file
}

# Simulating IP address update
update_ip() {
    local desiredIPAddress="$1"       # Capturing desired IP address
    validate_ip "$desiredIPAddress"   # Validating IP address format
    log_message "INFO" "Simulating IP update to $desiredIPAddress"  # Logging IP update
    echo "IP updated to $desiredIPAddress (simulated)" > ./netplan_simulated.yaml  # Writing IP update to simulated YAML
}

# Simulating adding a host entry
update_hostentry() {
    local desiredName="$1"            # Capturing desired hostname
    local desiredIPAddress="$2"       # Capturing desired IP address

    if ! grep -q "$desiredIPAddress $desiredName" ./hosts_simulated; then
        log_message "INFO" "Simulating adding host entry: $desiredIPAddress $desiredName"  # Logging host entry addition
        echo "$desiredIPAddress $desiredName" >> ./hosts_simulated  # Adding entry to simulated hosts file
    else
        log_message "INFO" "Host entry already exists: $desiredIPAddress $desiredName"  # Logging existing entry
    fi
}

# Showing help information
show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -verbose              Enabling verbose mode"
    echo "  -name <hostname>      Setting system hostname"
    echo "  -ip <address>         Setting system IP address"
    echo "  -hostentry <ip> <name> Adding or confirming host entry"
    echo "  -help                 Showing this help message"
}

# Parsing command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -verbose)                    # Enabling verbose mode
            verbose=1
            shift
            ;;
        -name)                       # Handling hostname update
            [[ -z "$2" ]] && log_message "ERROR" "Missing hostname for -name option" && show_help && exit 1
            update_hostname "$2"
            shift 2
            ;;
        -ip)                         # Handling IP update
            [[ -z "$2" ]] && log_message "ERROR" "Missing IP address for -ip option" && show_help && exit 1
            update_ip "$2"
            shift 2
            ;;
        -hostentry)                  # Handling host entry update
            [[ -z "$2" || -z "$3" ]] && log_message "ERROR" "Missing IP or hostname for -hostentry option" && show_help && exit 1
            update_hostentry "$2" "$3"
            shift 3
            ;;
        -help)                       # Displaying help message
            show_help
            exit 0
            ;;
        *)                            # Handling unknown options
            log_message "ERROR" "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

