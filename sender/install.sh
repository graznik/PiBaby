# Check for running OS.
# Needed for OS dependent commands.
check_for_os() {
    OS_FILE='/etc/os-release'
    if [ -f  $OS_FILE ]; then
	OS=$(awk -F "=" '/^NAME/ {print $2}' $OS_FILE | tr -d '"')
    else
	echo "Error: File $OS_FILE not found"
	exit 1
    fi

    if [ "$OS" == "Raspbian GNU/Linux" ]; then
	OS='Debian'
	echo "Error: Raspbian is not supported yet."
	exit 1
    elif [ "$OS" == "Arch Linux ARM" ]; then
        OS='Arch'
    else
        echo "Error: Unsupported OS."
        exit 1
    fi
    return 0
}


check_for_os()

if [ "$OS" == "Arch" ]; then
    # Use an existing WLAN by default
    install -m 0644 usr/lib/systemd/system/network.service /usr/lib/systemd/system/
    install -m 0644 etc/wpa_supplicant.conf /etc/
    systemctl enable network.service

    # Needed for AP mode (if no known WLAN is reachable)
    if [ ! -d "/etc/conf.d/" ]; then
	mkdir /etc/conf.d/
    fi
    install -m 0644 etc/conf.d/pibaby_network /etc/conf.d/pibaby_network
    install -m 0644 usr/lib/systemd/system/pibaby_network.service /usr/lib/systemd/system/
    install -m 0644 etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf
    install -m 0644 etc/dhcpd.conf /etc/dhcpd.conf

    # The main PiBaby service
    install -m 0644 usr/lib/systemd/system/pibaby.service /usr/lib/systemd/system/
    systemctl enable pibaby.service
fi

install -m 0755 usr/local/bin/pibaby_sender.sh /usr/local/bin/
