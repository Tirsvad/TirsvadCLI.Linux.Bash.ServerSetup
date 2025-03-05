#/bin/bash

## @fn setup_basic_firewall()
## @brief Setup a basic firewall
## @details
## This function sets up a basic firewall
## @param host The server host
## @param port The SSH port
## @param password The root password
## @return 1 if the basic firewall is not setup successfully
setup_basic_firewall() {
	local host=$1
	local port=$2
	local password=$3

	sed "s/<TCLI_SERVERSETUP_SSHPORT_HARDNESS>/${port}/g" ${TCLI_LINUX_BASH_SERVERSETUP_PATH_CONF}/nft/basic.txt > ${TCLI_LINUX_BASH_SERVERSETUP_PATH_CONF}/nft/basic.tmp

	mapfile -t lines < "${TCLI_LINUX_BASH_SERVERSETUP_PATH_CONF}/nft/basic.tmp"
	for line in "${lines[@]}"; do
		remote_ssh_as_root "$host" "$port" "$password" "$line"
	done
}

## @fn firewall_save_rules()
## @brief Save the firewall rules
## @details
## This function saves the firewall rules
## @param host The server host
## @param port The SSH port
## @param password The root password
## @return 1 if the firewall rules are not saved successfully
firewall_save_rules() {
	local host=$1
	local port=$2
	local password=$3

	remote_ssh_as_root $host $port $password "nft list ruleset > /etc/nftables.conf" || {
		return 1
	}
}

## @fn firewall_load_conf_at_boot()
## @brief Load the firewall config at boot
## @details
## ** Set server to load the firewall config at boot **
## This function loads the firewall config at boot
## @param host The server host
## @param port The SSH port
## @param password The root password
## @return 1 if the firewall config is not loaded at boot
firewall_load_conf_at_boot() {
	local host=$1
	local port=$2
	local password=$3

	remote_ssh_as_root $host $port $password "cp /usr/share/doc/nftables/examples/sysvinit/nftables.init /etc/init.d" || {
		return 1
	}
	remote_ssh_as_root $host $port $password "update-rc.d nftables.init defaults" || {
		return 1
	}
}

## @fn firewall_enable_service()
## @brief Enable the firewall service
## @details
## ** Enable the firewall service **
## This function enables the firewall service
## @param host The server host
## @param port The SSH port
## @param password The root password
## @return 1 if the firewall service is not enabled
fierwall_enable_service() {
	local host=$1
	local port=$2
	local password=$3

	remote_ssh_as_root $host $port $password "systemctl enable nftables" || {
		return 1
	}
}	
