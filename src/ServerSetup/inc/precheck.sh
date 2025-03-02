#!/bin/bash

## @file
## @brief Precheck for Server Setup
## @details
## **Precheck for Server Setup**

## @fn precheck()
## @brief Checking Dependencies
## @details
## This function checks if the dependencies are installed on the system
## - sshpass
## - nc (netcat)
## @return 0 if all dependencies are installed
## @return 1 if any dependencies are missing
precheck() {
	local err = 0
	TCLI_LINUX_BASH_SERVERSTUP_PRECHECK_ERROR_MESSAGE=""
	# We need sshpass
	TCLI_LINUX_BASH_SERVERSTUP_PRECHECK_ERROR_MESSAGE="$TCLI_LINUX_BASH_SERVERSTUP_PRECHECK_ERROR_MESSAGE\n${RED}sshpass need to be installed${NC}\n"
	if ! (which sshpass > /dev/null); then
		[ $TCLI_LINUX_BASH_DISTRIBUTION_ID == "Debian GNU/Linux" ] && TCLI_LINUX_BASH_SERVERSTUP_PRECHECK_ERROR_MESSAGE="${TCLI_LINUX_BASH_SERVERSTUP_PRECHECK_ERROR_MESSAGE}sudo apt install sshpass\n"
		[ $TCLI_LINUX_BASH_DISTRIBUTION_ID == "Ubuntu" ] && TCLI_LINUX_BASH_SERVERSTUP_PRECHECK_ERROR_MESSAGE="${TCLI_LINUX_BASH_SERVERSTUP_PRECHECK_ERROR_MESSAGE}sudo apt install sshpass\n" 
		err = 1
	fi

	# We need nc (netcat)
	if ! (which nc > /dev/null); then
		TCLI_LINUX_BASH_SERVERSTUP_PRECHECK_ERROR_MESSAGE="$TCLI_LINUX_BASH_SERVERSTUP_PRECHECK_ERROR_MESSAGE\n${RED}netcat need to be installed${NC}\n"
		[ $TCLI_LINUX_BASH_DISTRIBUTION_ID == "Debian GNU/Linux" ] && TCLI_LINUX_BASH_SERVERSTUP_PRECHECK_ERROR_MESSAGE="${TCLI_LINUX_BASH_SERVERSTUP_PRECHECK_ERROR_MESSAGE}sudo apt install netcat\n"
		[ $TCLI_LINUX_BASH_DISTRIBUTION_ID == "Ubuntu" ] && TCLI_LINUX_BASH_SERVERSTUP_PRECHECK_ERROR_MESSAGE="${TCLI_LINUX_BASH_SERVERSTUP_PRECHECK_ERROR_MESSAGE}sudo apt install netcat\n"
		err = 1
	fi

	return $err
}
