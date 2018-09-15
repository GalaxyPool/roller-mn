#!/bin/bash
bla=$(tput setaf 0)
red=$(tput setaf 1)
gre=$(tput setaf 2)
yel=$(tput setaf 3)
blu=$(tput setaf 4)
end=$(tput sgr0)

COIN_PORT=8545
DAEMON_PORT=30303
DAEMON_NAME='geth'
NODEIP=$(curl -s4 api.ipify.org)



function display_banner(){
	echo -n $gre
	cat << _banner
  ╔═══════════════════════════════════════════════════════════════════╗
  ║   __  __    _    ____ _____ _____ ____  _   _  ___  ____  _____   ║
  ║  |  \/  |  / \  / ___|_   _| ____|  _ \| \ | |/ _ \|  _ \| ____|  ║
  ║  | |\/| | / _ \ \___ \ | | |  _| | |_) |  \| | | | | | | |  _|    ║
  ║  | |  | |/ ___ \ ___) || | | |___|  _ <| |\  | |_| | |_| | |___   ║
  ║  |_|  |_/_/   \_\____/ |_| |_____|_| \_\_| \_|\___/|____/|_____|  ║
  ║                                                                   ║
  ║      ___  ____  __   __   _______                                 ║
  ║     / _ \/ __ \/ /  / /  / __/ _ \                                ║
  ║    / , _/ /_/ / /__/ /__/ _// , _/        Script by Galaxy Pool   ║
  ║   /_/|_|\____/____/____/___/_/|_|         https://fb.com/duyk16   ║
  ║                                                                   ║
  ╚═══════════════════════════════════════════════════════════════════╝
_banner
	echo -n $end
}

# CHECK UBUNTU VERSION
function checks_ubuntu() {
	if [[ $(lsb_release -d) != *16.04* ]]; then
		echo -e "${red}You are not running Ubuntu 16.04. Installation is cancelled.${end}"
		exit 1
	fi
	if [[ $EUID -ne 0 ]]; then
		echo -e "${red}Script must be run as root.${end}"
		exit 1
	fi
}

function choice() {
	echo -n $gre
	cat << _choice
           1) INSTALL MASTERNODE
           2) INPUT DATA
           3) MASTERNODE INFORMATIONS
           4) MASTERNODE STATUS
           5) RESTART SERVICE
           6) REMOVE OLD FILE
           7) EXIT
_choice
	echo -n $end  
	read -r -p "  ${yel}Enter your choice [1-6]: $end" choice
	if [ $choice = 1 ]; then
		systemctl stop ${DAEMON_NAME}.service
		remove_file
		download_file
		install_firewall
		install_mn
		echo "${yel}Getting informations ..."
		sleep 10
		footer
	elif [ $choice = 2 ]; then
	read -r -p "  ${yel}Enter your choice Masternode IP: $end" NODEIP
	read -r -p "  ${yel}Enter your choice Coin port (default is 8545): $end" COIN_PORT
	read -r -p "  ${yel}Enter your choice Daemon port (default is 30303): $end" DAEMON_PORT
	read -r -p "  ${yel}Enter your choice Daemon name: $end" DAEMON_NAME
	read -r -p "  ${yel}Back to menu [y/n]: $end" back
		case "$back" in
         [yY][eE][sS]|[yY])
          menu
             ;;
         *)
             exit
             ;;
		esac
	elif [ $choice = 3 ]; then
		footer
	elif [ $choice = 4 ]; then
		systemctl status ${DAEMON_NAME}.service
		read -r -p "  ${yel}Back to menu [y/n]: $end" back
		case "$back" in
         [yY][eE][sS]|[yY])
          menu
             ;;
         *)
             exit
             ;;
		esac
	elif [ $choice = 5 ]; then
		systemctl restart ${DAEMON_NAME}.service
		echo "  ${end}Restart done."
		read -r -p "  ${yel}Back to menu [y/n]: $end" back
		case "$back" in
         [yY][eE][sS]|[yY])
          menu
             ;;
         *)
             exit
             ;;
		esac
	elif [ $choice = 6 ]; then
		echo "  ${yel}Removing old file ..."
		remove_file
		echo "  ${yel}Remove complete"
		read -r -p "  Back to menu [y/n]: $end" back
		case "$back" in
         [yY][eE][sS]|[yY])
          menu
             ;;
         *)
             exit
             ;;
		esac
	elif [ $choice = 7 ]; then
		exit
	else
		echo " ${yel} You must choice from 1-6. ${end}"
	fi
}

# FOOTER
footer () {
	clear
	echo -n $gre && echo
	cat << _success
  --------------------- SUCCESS CONFIGURATION -----------------------
_success
	echo
	echo "  ${red}Masternode IP:${end} ${NODEIP}"
	echo "  ${red}Masternode PORT:${end} $(journalctl -u ${DAEMON_NAME}.service | grep 'HTTP endpoint opened' | awk '{print $11}' | awk '{print $1}' | grep -o -P '(?<=http://0.0.0.0:).*' | tail -1)"
	echo "  ${red}Masternode ID:${end} $(journalctl -u ${DAEMON_NAME}.service | grep 'UDP listener up' | awk '{print $11}' | grep -o -P '(?<=node://).*(?=@)' | tail -1)"
	echo -n $yel && echo
	cat << _information
     /- This script only work with Ubuntu 16.04 x64
     /- Script made by Duy Nguyen
     /- Contact: fb.com/duyk16
     /- Donations:
           * ETH/ETC: 0xBEB1B4ae55A1C0873c60947724Ae8b58B7Def191
           * ROLLER: 0x0eead76e3edd5a09879a42aeb00eacbb77d641b4
_information
	echo -n $gre && echo
	echo "  -----------------------------------------------------------------"
	echo -n $end && echo
	read -r -p " ${yel}Back to menu [y/n]: $end" back
	case "$back" in
     [yY][eE][sS]|[yY])
      menu
         ;;
     *)
         exit
         ;;
	esac
}

# DOWNLOAD NEEDED FILE
function download_file() {
	echo "${yel} Download needed file ...${end}"
	sleep 3
    wget https://github.com/roller-project/roller/releases/download/1.2.1/geth-linux-amd64.zip
}

function install_firewall() {
	echo -e "Installing and setting up firewall to allow ingress on port ${yel}${COIN_PORT}${end}"
	apt-get install -y ufw
	ufw allow ${COIN_PORT} comment "ROLLER MN port" >/dev/null
	ufw allow ${DAEMON_PORT} >/dev/null
	ufw allow ssh comment "SSH" >/dev/null 2>&1
	ufw limit ssh/tcp >/dev/null 2>&1
	ufw default allow outgoing >/dev/null 2>&1
	echo "y" | ufw enable >/dev/null 2>&1
}

# INSTALL FUNCTION
function install_mn() {
	cd
	apt-get -y install unzip wget git curl
	unzip geth-linux-amd64.zip
	mv ~/geth-linux-amd64/geth-linux-amd64 /usr/sbin/${DAEMON_NAME}
	cat > /tmp/${DAEMON_NAME}.service << EOL
[Unit]
Description=$COIN_NAME Client -- masternode service
After=network.target
[Service]
Type=simple
Restart=always
RestartSec=30s
ExecStart=/usr/sbin/${DAEMON_NAME} --masternode --rpcport ${COIN_PORT} --port ${DAEMON_PORT} --maxpeers 40 --rpcvhosts * --datadir /root/${DAEMON_NAME}
[Install]
WantedBy=default.target
EOL
	mv /tmp/${DAEMON_NAME}.service /etc/systemd/system
	systemctl enable ${DAEMON_NAME} && systemctl start ${DAEMON_NAME}
	rm -rf /root/geth-linux-amd64.zip
	rm -rf /root/geth-linux-amd64/	
}

# REMOVE OLD FILE
function remove_file () {
	systemctl stop masternode.service
	systemctl stop ${DAEMON_NAME}.service
	rm -rf /root/geth-linux-amd64.zip
	rm -rf /root/geth-linux-amd64/
	rm -rf /usr/sbin/geth
	rm -rf /tmp/${DAEMON_NAME}.service
	rm -rf /root/.roller/
	rm -rf /etc/systemd/system/${DAEMON_NAME}.service
}

function menu() {
	clear
	display_banner
	checks_ubuntu
	choice
}

menu
