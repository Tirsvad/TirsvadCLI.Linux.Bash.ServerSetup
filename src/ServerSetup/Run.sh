#/bin/bash

. ./serverSetup.sh

init_handler() {
	init || {
		echo "Server Setup not initialized"
		exit 1
	}
}

is_settigns_file_handler() {
	is_settigns_file || {
		echo "Settings file needs to be filled out"
		exit 1
	}
}

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

checking_settings_handler() {
	tcli_linux_bash_logger_infoscreen "Checking Settings"
	validate_settings || {
		tcli_linux_bash_logger_infoscreenFailed
		printf "\n${RED}Settings file is not valid${NC}\n"
		exit 1
	}
	tcli_linux_bash_logger_infoscreenDone
}

check_server_connection_handler() {
	tcli_linux_bash_logger_infoscreen "Checking Server Connection"
	can_connect_server $SERVER_HOST $SERVER_PORT $ROOT_PASSWORD || {
		err=$?
		tcli_linux_bash_logger_infoscreenFailed
		if [ $err -eq 1 ]; then
			printf "\n${RED}Could not connect to the server ${SERVER_HOST}:${SERVER_PORT} ${NC}\n"
			exit 1
		fi
		if [ $err -eq 2 ]; then
			printf "\n${RED}SSH could not be connected{NC}\n"
			exit 1
		fi
		printf "\n${RED}Could not connect to the server. UNKNOW why!${NC}\n"
		exit 1
	}
	tcli_linux_bash_logger_infoscreenDone
}

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
#checking_settings_handler
#check_server_connection_handler
#create_user_handler
#user_sshkey_handler
