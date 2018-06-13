#!/bin/bash

## sparks masternode upgrade
## This upgrade script should be used when migrating from versions 0.12.3.1 or higher to latest release
## This script will download the latest version from github and replace the required files
## as a precaution always make backups before any upgrade
##
## This script is designed to work with a sparks installation done as the root user and the daemon running as a service
## https://github.com/SparksReborn/SparksMasternodeInstall
## to execute this script use
## wget -q https://raw.githubusercontent.com/SparksReborn/SparksMasternodeInstall/master/sparks_masternode_upgrade.sh && bash sparks_masternode_upgrade.sh

TMP_FOLDER=$(mktemp -d)
CONFIG_FILE='sparks.conf'
CONFIGFOLDER='/root/.sparkscore'
COIN_DAEMON='sparksd'
COIN_VERSION='v0.12.3.2'
COIN_CLI='sparks-cli'
COIN_PATH='/usr/local/bin/'
COIN_REPO='https://github.com/SparksReborn/sparkspay.git'
COIN_TGZ='https://github.com/SparksReborn/sparkspay/releases/download/v0.12.3.2/sparkscore-0.12.3.2-linux64.tar.gz'
COIN_BOOTSTRAP='https://github.com/SparksReborn/sparkspay/releases/download/bootstrap/bootstrap.dat'
COIN_ZIP=$(echo $COIN_TGZ | awk -F'/' '{print $NF}')
SENTINEL_REPO='https://github.com/SparksReborn/sentinel.git'
COIN_NAME='sparks'
COIN_PORT=8890
RPC_PORT=8818

NODEIP=$(curl -s4 icanhazip.com)

BLUE="\033[0;34m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
PURPLE="\033[0;35m"
RED='\033[0;31m'
GREEN="\033[0;32m"
NC='\033[0m'
MAG='\e[1;35m'


purgeOldInstallation() {
  echo -e "${GREEN}sparks Masternode Auto Upgrade script"
  echo -e "${GREEN}Original script by ${RED}Bit_Yoda${GREEN}, This Upgrade script by ${RED}DrWeez"
  echo -e "${GREEN}Hold onto your hat..  starting with $COIN_NAME Daemon $COIN_VERSION${NC} upgrade"
  echo
  echo -e "${GREEN}Stop and remove old ${RED}$COIN_NAME ${GREEN} files${NC}"
  #kill wallet daemon
  systemctl stop Sparks.service > /dev/null 2>&1
  sudo killall Sparksd > /dev/null 2>&1
  systemctl stop sparks.service > /dev/null 2>&1
  sudo killall sparksd > /dev/null 2>&1
  #remove old files
  echo -e "${GREEN}do quick cleanup${NC}"
  #  rm /root/.sparkscore/sentinel.log > /dev/null 2>&1
  #  rm /root/.sparkscore/debug.log > /dev/null 2>&1
    rm /root/.sparkscore/bootstrap.dat.old > /dev/null 2>&1
  #  rm -r /root/.sparkscore/blocks > /dev/null 2>&1
  #  rm -r /root/.sparkscore/chainstate> /dev/null 2>&1
  echo -e "${GREEN} remove binaries and Sparks utilities${NC}"
  #cleanup old Sparks
  cd /usr/local/bin && sudo rm Sparks-cli Sparks-tx Sparksd > /dev/null 2>&1 && cd
  cd /usr/bin && sudo rm Sparks-cli Sparks-tx Sparksd > /dev/null 2>&1 && cd
  #cleanup new
  cd /usr/local/bin && sudo rm sparks-cli sparks-tx sparksd > /dev/null 2>&1 && cd
  cd /usr/bin && sudo rm sparks-cli sparks-tx sparksd > /dev/null 2>&1 && cd
  echo -e "${GREEN}* Done${NONE}";
}


function download_node() {
  echo -e "${GREEN}Downloading and installing $COIN_NAME Daemon $COIN_VERSION${NC}"
  cd $TMP_FOLDER >/dev/null 2>&1
  wget -q $COIN_TGZ
  compile_error
  tar xvzf $COIN_ZIP >/dev/null 2>&1
  cd sparkscore-0.12.3/bin
  chmod +x $COIN_DAEMON $COIN_CLI
  cp $COIN_DAEMON $COIN_CLI $COIN_PATH
  #cp sparks* $COIN_PATH
  cd ~ >/dev/null 2>&1
  rm -rf $TMP_FOLDER >/dev/null 2>&1
  clear
}

function enable_firewall() {
  echo -e "Installing and setting up firewall to allow ingress on port ${GREEN}$COIN_PORT${NC}"
  ufw allow $COIN_PORT/tcp comment "$COIN_NAME MN port" >/dev/null
  ufw allow ssh comment "SSH" >/dev/null 2>&1
  ufw limit ssh/tcp >/dev/null 2>&1
  ufw default allow outgoing >/dev/null 2>&1
  echo "y" | ufw enable >/dev/null 2>&1
}

function grab_bootstrap() {
  cd $CONFIGFOLDER
  wget -q $COIN_BOOTSTRAP
}

function compile_error() {
if [ "$?" -gt "0" ];
 then
  echo -e "${RED}Failed to compile $COIN_NAME. Please investigate.${NC}"
  exit 1
fi
}


function checks() {
if [[ $(lsb_release -d) != *16.04* ]]; then
  echo -e "${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

#if [ -n "$(pidof $COIN_DAEMON)" ] || [ -e "$COIN_DAEMOM" ] ; then
#  echo -e "${RED}$COIN_NAME is already installed.${NC}"
#  exit 1
#fi
}

function enable_fail2ban() {
  echo "installing fail 2 ban"
  apt -y install fail2ban >/dev/null 2>&1
  systemctl enable fail2ban >/dev/null 2>&1
  systemctl start fail2ban >/dev/null 2>&1
  echo "Fail2Ban done"
}

function important_information() {
 echo
 echo -e "Please check ${RED}$COIN_NAME${NC} is running with the following command: ${RED}systemctl status $COIN_NAME.service${NC}"
 echo -e "Use ${RED}$COIN_CLI masternode status${NC} to check your MN."
 if [[ -n $SENTINEL_REPO  ]]; then
 echo -e "${RED}Sentinel${NC} is installed in ${RED}/root/sentinel_$COIN_NAME${NC}"
 echo -e "Sentinel logs is: ${RED}$CONFIGFOLDER/sentinel.log${NC}"
 fi
 echo -e "Fail2Ban log is: ${RED}sudo tail -f /var/log/fail2ban.log${NC}"
# echo
# echo -e "${YELLOW}run sparks-cli masternode status"
# echo -e "${YELLOW}if status 'Masternode successfully started' no further action required"
# echo
 echo -e "${BLUE}================================================================================================================================"
 echo -e "${CYAN}Original install script by ${BLUE}Real_Bit_Yoda${CYAN}. Follow twitter to stay updated.  https://twitter.com/Real_Bit_Yoda${NC}"
 echo -e "${BLUE}================================================================================================================================${NC}"
 echo -e "${CYAN}This upgrade script by ${RED}DrWeez "
 echo -e "${BLUE}================================================================================================================================${NC}"
 echo -e "${GREEN}Donations accepted but never required.${NC}"
 echo -e "${BLUE}================================================================================================================================${NC}"
 echo -e "${YELLOW}DrWeez SPK: GTWBJHbZreZaPmNiYvd2HAmQRXxBh3dTTZ"
 echo -e "${BLUE}================================================================================================================================${NC}"
 echo -e "${YELLOW}Real_Bit_Yoda BCH: qzgnck23pwfag8ucz2f0vf0j5skshtuql5hmwwjhds"
 echo -e "${YELLOW}Real_Bit_Yoda ETH: 0x765eA1753A1eB7b12500499405e811f4d5164554"
 echo -e "${YELLOW}Real_Bit_Yoda LTC: LNt9EQputZK8djTSZyR3jE72o7NXNrb4aB${NC}"
 echo -e "${BLUE}================================================================================================================================${NC}"

}

#function setup_node() {
  #get_ip
  #create_config
  #create_key
  #update_config
  #enable_firewall
  #enable_fail2ban
  #install_sentinel
  #configure_sentinel
  #grab_bootstrap
  #important_information
  #configure_systemd
  #created_upgrade
#}


##### Main #####
clear

purgeOldInstallation #removed old Sparks* moves .Sparks to .sparkscore
checks # basic checks
#prepare_system #upgrades systemd
download_node # downloads new version extracts and copies
#setup_node # installs sentinal / reconfigures crontab && removes old service and creats new.
#print the info
important_information
#start the node again
systemctl start sparks.service > /dev/null 2>&1
#finished
