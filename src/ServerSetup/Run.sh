#/bin/bash

. ./serverSetup.sh

## @fn init_handler()
## @brief Initialize the Server Setup
## @details
## This function initializes the Server Setup
## - Set the path structure
## - Load Constants
## - Load Distribution
## - Load Logger
## @exit 1 if the Server Setup is not initialized
init_handler() {
	init || {
		echo "Server Setup not initialized"
		exit 1
	}
}

## @fn is_settigns_file_handler()
## @brief Check if the settings file exists
## @details
## This function checks if the settings file exists
## - If the settings file does not exist, it will be copied from the example file
## @exit 1 if the settings file does not exist
is_settigns_file_handler() {
	is_settigns_file || {
		echo "Settings file needs to be filled out"
		exit 1
	}
}

## @fn checking_dependencies_handler()
## @brief Check dependencies
## @details
## This function checks if the dependencies are installed
## @exit 1 if the dependencies are not installed
checking_dependencies_handler() {
	tcli_linux_bash_logger_infoscreen "Checking Dependencies"
	precheck || {
		tcli_linux_bash_logger_infoscreenFailed
		printf "\n${RED}${TCLI_LINUX_BASH_SERVERSTUP_PRECHECK_ERROR_MESSAGE}${NC}\n"
		printf "${RED}Please install the dependencies and run the script again${NC}\n"
		exit 1
	}
	tcli_linux_bash_logger_infoscreenDone
}

## @fn checking_settings_handler()
## @brief Check settings
## @details
## This function checks if the settings file is valid
## @exit 1 if the settings file is not valid
checking_settings_handler() {
	tcli_linux_bash_logger_infoscreen "Checking Settings"
	validate_settings || {
		tcli_linux_bash_logger_infoscreenFailed
		printf "\n${RED}Settings file is not valid${NC}\n"
		exit 1
	}
	tcli_linux_bash_logger_infoscreenDone
}

## @fn check_server_connection_handler()
## @brief Check server connection
## @details
## This function checks if the server can be connected
## @exit 1 if the server can not be connected
## @exit 2 if the SSH can not be connected
check_server_connection_handler() {
	tcli_linux_bash_logger_infoscreen "Checking Server Connection"
	can_connect_server $SERVER_HOST $SERVER_PORT $ROOT_PASSWORD || {
		err=$?
		tcli_linux_bash_logger_infoscreenFailed
		if [ $err -eq 1 ]; then
			printf "\n${RED}Could not connect to the server ${SERVER_HOST}:${SERVER_PORT} ${NC}\n"
			exit $err
		fi
		if [ $err -eq 2 ]; then
			printf "\n${RED}SSH could not be connected{NC}\n"
			exit $err
		fi
		printf "\n${RED}Could not connect to the server. UNKNOW why!${NC}\n"
		exit $err
	}
	tcli_linux_bash_logger_infoscreenDone
}

## @fn update_os_handler()
## @brief Update the OS
## @details
## This function updates the OS
## @exit 1 if the OS is not updated
update_os_handler() {
	tcli_linux_bash_logger_infoscreen "Updating OS"
	reconfigure_dpkg || {
		tcli_linux_bash_logger_infoscreenFailed
		printf "\n${RED}Failed to reconfigure dpkg${NC}\n"
		exit 1
	}
	update_os || {
		tcli_linux_bash_logger_infoscreenFailed
		printf "\n${RED}Failed to update OS${NC}\n"
		exit 1
	}
	tcli_linux_bash_logger_infoscreenDone
}

## @fn upgrade_os_handler()
## @brief Upgrade the OS
## @details
## This function upgrades the OS
## @exit 1 if the OS is not upgraded
upgrade_os_handler() {
	tcli_linux_bash_logger_infoscreen "Upgrading OS"
	upgrade_os || {
		tcli_linux_bash_logger_infoscreenFailed
		printf "\n${RED}Failed to upgrade OS${NC}\n"
		exit 1
	}
	tcli_linux_bash_logger_infoscreenDone
}

## @fn create_user_handler()
## @brief Create a user
## @details
## This function creates a user
## @exit 1 if the user is not created
create_user_handler() {
	tcli_linux_bash_logger_infoscreen "Creating User"
	remote_ssh_as_root $SERVER_HOST $SERVER_PORT $ROOT_PASSWORD "useradd -m -s /bin/bash ${SU_NAME}; chpasswd chpasswd <<< \"${SU_NAME}:${SU_PASSWORD}\"" || {
		tcli_linux_bash_logger_infoscreenFailed
		printf "\n${RED}Failed to create user${NC}\n"
		exit 1
	}
	remote_ssh_as_root $SERVER_HOST $SERVER_PORT $ROOT_PASSWORD "usermod -a -G sudo ${SU_NAME}" || {
		tcli_linux_bash_logger_infoscreenFailed
		printf "\n${RED}Failed to create user${NC}\n"
		exit 1
	}
	tcli_linux_bash_logger_infoscreenDone
}

## @fn user_sshkey_handler()
## @brief Upload SSH key to server
## @details
## This function uploads a SSH key to the server
## @exit 1 if the SSH key is not uploaded
user_sshkey_handler() {
	tcli_linux_bash_logger_infoscreen "Checking SSH Key"
	#has_user_ssh_key_else_create_one || {
	#	tcli_linux_bash_logger_infoscreenFailed
	#	printf "\n${RED}Failed to create SSH key${NC}\n"
	#	exit 1
	#}
	upload_ssh_key_to_server $SERVER_HOST $SERVER_PORT $SU_NAME $SU_PASSWORD || {
		tcli_linux_bash_logger_infoscreenFailed
		printf "\n${RED}Failed to upload SSH key to server${NC}\n"
		exit 1
	}
	tcli_linux_bash_logger_infoscreenDone
}
init_handler
is_settigns_file_handler
tcli_linux_bash_logger_init "${TCLI_LINUX_BASH_SERVERSETUP_PATH_LOG}/log" "ServerSetup"

# Clear the screen
clear

tcli_linux_bash_logger_title "Server Setup"
checking_dependencies_handler
checking_settings_handler
check_server_connection_handler
update_os_handler
upgrade_os_handler
create_user_handler
user_sshkey_handler
