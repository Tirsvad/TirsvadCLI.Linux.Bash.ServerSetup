#/bin/bash

## @file
## @author Jens Tirsvad Nielsen
## @brief Setup a secure server
## @details
## **Server Setup**
##
## With support for
## - webserver nginx with encryption (ssl)
## - Email server postfix with gui postfix admin
## - Database server postgresql
##
## @todo
## - Add streaming server
## - More configuration for email server

init() {
	declare IFS=$'\n\t'

	# Setting path structure and file
	declare -g TCLI_LINUX_BASH_SERVERSETUP_PATH_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

	# Load Constants
	. "${TCLI_LINUX_BASH_SERVERSETUP_PATH_ROOT}/inc/constants.sh"

	# Load Distribution
	if [ -z "$TCLI_LINUX_BASH_DISTRIBUTION" ]; then
		echo "Downloading Distribution"
		mkdir -p "${TCLI_LINUX_BASH_SERVERSETUP_PATH_VENDOR}/Distribution"
		curl -sL https://github.com/TirsvadCLI/Linux.Bash.Distribution/archive/refs/heads/main.tar.gz -o /tmp/Linux.Bash.Distribution.tar.gz
		tar -xzf /tmp/Linux.Bash.Distribution.tar.gz --strip-components=2 -C /tmp/
		cp -rf /tmp/Distribution "${TCLI_LINUX_BASH_SERVERSETUP_PATH_VENDOR}/"
		rm -rf /tmp/Distribution
	fi
	echo "Loading Distribution"
	. "${TCLI_LINUX_BASH_SERVERSETUP_PATH_VENDOR}/Distribution/Run.sh"

	# Load Logger
	if [ -z "$TCLI_LINUX_BASH_LOGGER" ]; then
		echo "Downloading Logger"
		mkdir -p "${TCLI_LINUX_BASH_SERVERSETUP_PATH_VENDOR}/Logger"
		curl -sL https://github.com/TirsvadCLI/Linux.Bash.Logger/archive/refs/heads/main.tar.gz -o /tmp/Linux.Bash.Logger.tar.gz
		tar -xzf /tmp/Linux.Bash.Logger.tar.gz --strip-components=2 -C /tmp/
		cp -rf /tmp/Logger "${TCLI_LINUX_BASH_SERVERSETUP_PATH_VENDOR}/"
		rm -rf /tmp/Logger
	fi
	echo "Loading Logger"
	. "${TCLI_LINUX_BASH_SERVERSETUP_PATH_VENDOR}/Logger/Run.sh"

	tcli_linux_bash_logger_init "${TCLI_LINUX_BASH_SERVERSETUP_PATH_LOG}/log" "ServerSetup"

	# Clear the screen
	clear

	tcli_linux_bash_logger_title "Server Setup"

	tcli_linux_bash_logger_infoscreen "Checking Dependencies"
	# Load Precheck
	. "${TCLI_LINUX_BASH_SERVERSETUP_PATH_INC}/precheck.sh"
	precheck
	[ $? -ne 0 ] && {
		tcli_linux_bash_logger_infoscreenFailed
		printf "\n${RED}${TCLI_LINUX_BASH_SERVERSTUP_PRECHECK_ERROR_MESSAGE}${NC}\n"
		printf "${RED}Please install the dependencies and run the script again${NC}\n"
		exit 1
	}
}

check_dependicies() {
	script=$1
	scriptName=$2

	eval \$1${scriptName} > /dev/null
	if [ $? -ne 0 ]; then
		printf "\n${RED}${scriptName} need to be installed"
		[ $DISTRIBUTION_ID == "Debian GNU/Linux" ] && printf "sudo apt install ${scriptName}${NC}" >&3
		[ $DISTRIBUTION_ID == "Ubuntu" ] && printf "sudo apt install ${scriptName}${NC}" >&3
		exit 1
	fi
}

# Check if the script is being sourced or executed
# If the script is executed, print an error message and exit with an error code.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	echo "This script is intended to be sourced, not executed."
	exit 1
fi
