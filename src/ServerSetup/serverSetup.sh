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


## @fn init()
## @brief Initialize the Server Setup
## @details
## This function initializes the Server Setup
## - Set the path structure
## - Load Constants
## - Load Distribution
## - Load Logger
## @return 1 if the Server Setup is not initialized
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
		curl -sL $TCLI_LINUX_BASH_DISTRIBUTION_DOWNLOAD -o /tmp/Linux.Bash.Distribution.tar.gz
		tar -xzf /tmp/Linux.Bash.Distribution.tar.gz --strip-components=2 -C /tmp/
		cp -rf /tmp/Distribution "${TCLI_LINUX_BASH_SERVERSETUP_PATH_VENDOR}/"
		rm -rf /tmp/Distribution
	fi
	echo "Loading Distribution"
	. "${TCLI_LINUX_BASH_SERVERSETUP_PATH_VENDOR}/Distribution/Run.sh"
	if [ $? -ne 0 ]; then
		return 1
	fi

	# Load Logger
	if [ -z "$TCLI_LINUX_BASH_LOGGER" ]; then
		echo "Downloading Logger"
		mkdir -p "${TCLI_LINUX_BASH_SERVERSETUP_PATH_VENDOR}/Logger"
		curl -sL $TCLI_LINUX_BASH_LOGGER_DOWNLOAD -o /tmp/Linux.Bash.Logger.tar.gz
		tar -xzf /tmp/Linux.Bash.Logger.tar.gz --strip-components=2 -C /tmp/
		cp -rf /tmp/Logger "${TCLI_LINUX_BASH_SERVERSETUP_PATH_VENDOR}/"
		rm -rf /tmp/Logger
	fi
	echo "Loading Logger"
	. "${TCLI_LINUX_BASH_SERVERSETUP_PATH_VENDOR}/Logger/Run.sh"
	if [ $? -ne 0 ]; then
		return 1
	fi
}

## @fn is_settigns_file()
## @brief Check if the settings file exists
## @details
## This function checks if the settings file exists
## - If the settings file does not exist, it will be copied from the example file
## @return 1 if the settings file does not exist
is_settigns_file() {
	if [ ! -f "${TCLI_LINUX_BASH_SERVERSETUP_PATH_CONF}/settings.json" ]; then
		cp "${TCLI_LINUX_BASH_SERVERSETUP_PATH_CONF}/settings.example.json" "${TCLI_LINUX_BASH_SERVERSETUP_PATH_CONF}/settings.json"
		return 1
	fi
}

## @fn precheck()
## @brief Checking Dependencies
## @details
## This function checks if the dependencies are installed on the system
## - sshpass
## - nc (netcat)
## @return 1 if any dependencies are missing
precheck() {
	local err=0
	TCLI_LINUX_BASH_SERVERSTUP_PRECHECK_ERROR_MESSAGE=""
	
	# We need sshpass
	is_applications_avaible "sshpass" "sshpass"
	if [ $? -ne 0 ]; then
		err=1
	fi

	# We need nc (netcat)
	is_applications_avaible "nc" "netcat"
	if [ $? -ne 0 ]; then
		err=1
	fi

	return $err
}

## @fn is_applications_avaible()
## @brief Check if an application is installed
## @details
## This function checks if an application is installed on the system
## @param application The application to check for
## @param appPackage The package to install the application
## @return 1 if the application is not installed
is_applications_avaible() {
	local application=$1
	local appPackage=$2

	if [ -z $(which ${application}) ]; then
		TCLI_LINUX_BASH_SERVERSTUP_PRECHECK_ERROR_MESSAGE="$TCLI_LINUX_BASH_SERVERSTUP_PRECHECK_ERROR_MESSAGE\n${RED}${appPackage} need to be installed${NC}\n"
		[ $TCLI_LINUX_BASH_DISTRIBUTION_ID == "Debian GNU/Linux" ] && TCLI_LINUX_BASH_SERVERSTUP_PRECHECK_ERROR_MESSAGE="${TCLI_LINUX_BASH_SERVERSTUP_PRECHECK_ERROR_MESSAGE}sudo apt install ${appPackage}\n"
		[ $TCLI_LINUX_BASH_DISTRIBUTION_ID == "Ubuntu" ] && TCLI_LINUX_BASH_SERVERSTUP_PRECHECK_ERROR_MESSAGE="${TCLI_LINUX_BASH_SERVERSTUP_PRECHECK_ERROR_MESSAGE}sudo apt install ${appPackage}\n"
		return 1
	fi
}

## @fn is_dependicies_avaible()
## @brief Check if a script is installed
## @details
## This function checks if a script is installed on the system
## @param script The script to check for
## @param scriptName The name of the script
## @exit 1 if the script is not installed
is_dependicies_avaible() {
	script=$1
	scriptName=$2

	eval \$1${scriptName} > /dev/null
	if [ $? -ne 0 ]; then
		printf "\n${RED}${scriptName} need to be installed"
		exit 1
	fi
}

## @fn load_settings()
## @brief Load the settings from the settings file
## @details
## This function loads the settings from the settings file
## @param file The settings file
load_settings() {
	file=$1

	SERVER_HOST=$(jq -r '.server.host' $file < /dev/null)
	SERVER_PORT=$(jq -r '.server.port_for_ssh' $file < /dev/null)
	SERVER_PORT_HARDNEED=$(jq -r '.server.port_for_ssh_hardneed' $file < /dev/null)
	ROOT_PASSWORD=$(jq -r '.root.password' $file < /dev/null)
	SU_NAME=$(jq -r '.super_user.name' $file < /dev/null)
	SU_PASSWORD=$(jq -r '.super_user.password' $file < /dev/null)
}

## @fn validate_settings()
## @brief Validate the settings
## @details
## This function validates the settings from settings file
## - Check if the server host and port is set
## @return 1 if the settings are not valid
validate_settings() {
	load_settings $TCLI_LINUX_BASH_SERVERSETUP_FILE_SETTINGS

	# check if server host and port is set
	if [[ "$SERVER_HOST" == "null" || "$SERVER_PORT" == "null" ]]; then
		return 1
	fi
}

## @fn remote_ssh_as_root()
## @brief Run a command on a remote server as root
## @details
## This function runs a command on a remote server as root
## @param host The server host
## @param port The server port
## @param password The root password
## @param command The command to run
## @return 1 if the command is not run successfully
remote_ssh_as_root() {
	local host=$1
	local port=$2
	local password=$3
	local command=$4

	sshpass -p $password ssh -o StrictHostKeyChecking=no -o ConnectTimeout=20 root@$host -p $port "DEBIAN_FRONTEND=noninteractive $command; exit" > /dev/null

	if [ $? -ne 0 ]; then
		return 1
	fi
}

## @fn create_user()
## @brief Create a user on a remote server
## @details
## This function creates a user on a remote server
## @param host The server host
## @param port The server port
## @param password The root password
## @param user The user to create
## @param userPassword The user password
## @return 1 if the user is not created successfully
has_user_ssh_key_else_create_one() {
	if [ ! -f ~/.ssh/id_rsa ]; then
		create_ssh_key || {
			return 1
		}
	fi
}

## @fn create_ssh_key()
## @brief Create a ssh key
## @details
## This function creates a ssh key
## @return 1 if the ssh key is not created successfully
create_ssh_key() {
	ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ""
	if [ $? -ne 0 ]; then
		return 1
	fi
}

## @fn upload_ssh_key_to_server()
## @brief Upload a ssh key to a remote server
## @details
## This function uploads a ssh key to a remote server
## @param host The server host
## @param port The server port
## @param user The user to upload the ssh key to
## @param password The user password
## @return 1 if the ssh key is not uploaded successfully
upload_ssh_key_to_server() {
	local host=$1
	local port=$2
	local user=$3
	local password=$4
	sshpass -p ${password} ssh-copy-id -i ~/.ssh/id_rsa.pub -p ${port} ${user}@161.97.108.95 > /dev/null
	if [ $? -ne 0 ]; then
		return 1
	fi
}

## @fn can_connect_server()
## @brief Check if a server can be connected to
## @details
## This function checks if a server can be connected to
## @param server The server host
## @param port The server port
## @param password The root password
## @return 1 if the server can not be connected to
## @return 2 if the server can not be connected to via ssh
can_connect_server() {
	local server=$1
	local port=$2
	local password=$3

	nc -z $server $port > /dev/null
	if [ $? -ne 0 ]; then
		return 1
	fi

	sshpass -p $password ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@$server -p $port exit > /dev/null
	if [ $? -ne 0 ]; then
		return 2
	fi
}

## @fn reconfigure_dpkg()
## @brief Reconfigure dpkg
## @details
## This function reconfigures dpkg
## @return 1 if dpkg is not reconfigured
reconfigure_dpkg() {
	remote_ssh_as_root $SERVER_HOST $SERVER_PORT $ROOT_PASSWORD "dpkg --configure -a" || {
		return 1
	}
}

## @fn update_os()
## @brief Update the OS
## @details
## This function updates the OS
## @return 1 if the OS is not updated
update_os() {
	remote_ssh_as_root $SERVER_HOST $SERVER_PORT $ROOT_PASSWORD "apt-get update" || {
		return 1
	}
}

## @fn update_upgrade_os()
## @brief Update and upgrade the OS
## @details
## This function upgrades the OS
## @return 1 if the OS is not upgraded
upgrade_os(){
	remote_ssh_as_root $SERVER_HOST $SERVER_PORT $ROOT_PASSWORD "apt-get upgrade -y" || {
		return 1
	}
}

# Check if the script is being sourced or executed
# If the script is executed, print an error message and exit with an error code.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	echo "This script is intended to be sourced, not executed."
	exit 1
fi
