#!/bin/bash

# Receiver
REC_ADDR=''
REC_USER=''
HOME_ESSID=''
OS=''

# Initialize needed GPIOs
gpio_init() {
    # Switch (input)
    echo "7" > /sys/class/gpio/export
    echo "in" > /sys/class/gpio/gpio4/direction
    # LED (output)
    echo "4" > /sys/class/gpio/export
    echo "out" > /sys/class/gpio/gpio4/direction
}

# Check hardware switch for babyphone mode
check_mode() {
    # Babyphone hardware switch is set to off
    if [ `cat /sys/class/gpio/gpio7/value` == 0 ]; then
	exit 0
    fi
}

# Check for USB sound card. Only start babyphone mode
# if sound card is connected.
check_for_soundcard() {
    # Check for USB audio card.
    arecord -l | grep 'USB Audio' 1>/dev/null
    if [ $? -ne 0 ]; then
	logger "No audio device, going to exit."
	exit 1
    fi
    # REMOVE ME
    logger 'Found soundcard'
}

# Check for running OS.
# Needed for OS dependent commands.
check_for_os() {
    OS_FILE='/etc/os-release'
    if [ -f  $OS_FILE ]; then
	OS=$(awk -F "=" '/^NAME/ {print $2}' $OS_FILE | tr -d '"')
    else
	logger "File $OS_FILE not found"
	exit 1
    fi

    if [ "$OS" == "Raspbian GNU/Linux" ]; then
	OS='Debian'
    elif [ "$OS" == "Arch Linux ARM" ]; then
	OS='Arch'
    else
	logger "Unsupported OS"
	exit 1
    fi

    # REMOVE ME:
    logger "Found $OS OS"
}

# Check for home network. Change to AP mode if found none.
check_for_network() {
    ESSID=$(iwconfig wlan0 | grep 'ESSID:' | awk '{print $4}' |
	sed 's/ESSID://g' | sed 's/"//g')
    # Home network is unreachable
    if [ "$ESSID" != "$HOME_ESSID" ]; then
	# Get name of WLAN interface
	IF=$(iwconfig | grep IEEE |  awk '{print $1}')
	if [ "$IF" = "" ]; then
	    echo "No WLAN interface availlable"
	    exit 1
	else
	    # Interface availlable, start AP mode
	    if [ `systemctl start access_point.service` ]; then
		exit 1
	    fi
	    # DEBUG
	    logger "Configured network interface"

	    if [ `systemctl start hostapd.service` ]; then
		exit 1
	    fi
	    # DEBUG
	    logger 'Started AP daemon'

	    if [ `systemctl start dhcpd4.service` ]; then
		exit 1
	    fi
	    # DEBUG
	    logger 'Started DHCP server'
	fi
	fi
	# REMOVE ME
	logger 'Found home network'
	return 0
}

# Search for receiving host.
check_for_receiver() {
    while [ 1 ]; do
	# Check for open SSH port
	nc -z $REC_ADDR 22
	if [ $? -ne 0 ]; then
	    logger "Host is down."
	    sleep 5
	else
	    # FIXME: workaround
	    ssh ${REC_USER}@${REC_ADDR} killall -9 aplay
	    logger 'Found receiver, killed running aplay processes.'
	    return 0
	fi
    done
}

bphone() {
#    gpio_init
#    check_mode
    check_for_soundcard
    check_for_receiver
    OS=$(check_for_os)
    check_for_network
    # REMOVE ME:
    logger 'Starting to stream'
    # Start to stream
    # FIXME: Check return value
    arecord -D plughw:1,0 -f dat | ssh -C ${REC_USER}@${REC_ADDR} aplay -f dat
}
bphone &
exit 0
