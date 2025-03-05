#/bin/bash

## @file remote_connect
## @brief Connect to a remote server
## @details
## This file contains functions to connect to a remote server
## @author Jens Tirsvad Nielsen


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

	sshpass -p $password ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 root@$host -p $port "DEBIAN_FRONTEND=noninteractive $command; exit" > /dev/null

	if [ $? -ne 0 ]; then
		return 1
	fi
}

## @fn remote_ssh_as_su_sudo_command()
## @brief Run a command on a remote server as su
## @details
## This function runs a command on a remote server as su
## @param host The server host
## @param port The server port
## @param user The user
## @param password The user password
## @param command The command to run
## @return 1 if the command is not run successfully
remote_ssh_as_su_sudo_command() {
	local host=$1
	local port=$2
	local user=$3
	local password=$4
	local command=$5

	ssh $user@$host -p $port "echo $password | sudo -S $command"
}
