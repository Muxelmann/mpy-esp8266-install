#!/bin/bash

source config.sh

# Setting default arguments
STANDALONE="y"
INSTALL=1

for i in "$@"
do
case $i in
		-ns|--not_standalone)
		STANDALONE="n"
		shift # past argument with no value
		;;
		-e=*|--esp_sdk_dir=*)
		ESP_SDK_DIR="${i#*=}"
		shift # past argument=value
		;;
		-u|--update)
		INSTALL=0
		shift # past argument with no value
		;;
		-h|--help)
		cat .help_esp8266
		return
		;;
		*)
		# unknown option
		;;
esac
done

# Install all dependencies
sudo apt-get update
sudo apt-get install $ESP_DEPENDENCIES

# Check if you want to install or update
# (update removes SDK folder and re-installs from scratsh (slow...))
if [[ $INSTALL == 1 ]]; then
	printf "${GREEN} > Installing ESP's open-SDK (into ${ESP_SDK_DIR})${NC}\n"
	if [ -d $ESP_SDK_DIR ]; then
		printf "${GREEN} > ESP directory already found (consider updating with \"-u\" instead)${NC}\n"
	else
		git clone --recursive $ESP_GIT $ESP_SDK_DIR
	fi
else
	printf "${GREEN} > Updating ESP's open-SDK${NC}\n"
	if [[ -d ${ESP_SDK_DIR} ]]; then
		sudo rm -r ${ESP_SDK_DIR}
	fi
	git clone --recursive $ESP_GIT $ESP_SDK_DIR
fi

# Asks if you are ok to compile
function question { printf "${GREEN} > Cloning complete, do you want to build?${NC}"; }
function answer_yes { cd $ESP_SDK_DIR && make STANDALONE=$STANDALONE; cd ..; }
function answer_no { return; }

if [[ -d $ESP_SDK_DIR ]]; then
	ask question answer_yes answer_no
else
	printf "${RED} > $ESP_SDK_DIR not installed correctly!${NC}\n"
  return
fi

ESP_INSTALL_DIR=`realpath ./$ESP_SDK_DIR`

# Upon compilation, asks to add Xtensa compiler to path
function question { printf "${GREEN} > Do you wish to update ${YELLOW}.profile${GREEN}?${NC}"; }
function answer_yes {
	if grep -q "$ESP_INSTALL_DIR/xtensa-lx106-elf/bin" ~/.profile; then
		printf "${GREEN} > $ESP_INSTALL_DIR/xtensa-lx106-elf/bin already added to .profile.${NC}\n"
	else
		sudo echo "# ESP8266 binary" >> ~/.profile && sudo echo "export PATH=$ESP_INSTALL_DIR/xtensa-lx106-elf/bin:\$PATH" >> ~/.profile && sudo echo "" >> ~/.profile;
	fi
	if [[ ":$PATH:" == *"$ESP_INSTALL_DIR/xtensa-lx106-elf/bin:"* ]]; then
		printf "${GREEN} > ${YELLOW}$ESP_INSTALL_DIR/xtensa-lx106-elf/bin${GREEN} is already in \$PATH.${NC}\n"
	else
		export PATH=$ESP_INSTALL_DIR/xtensa-lx106-elf/bin:$PATH;
	fi
}
function answer_no {
	printf "${GREEN} > You need to call ${YELLOW}export PATH=$ESP_INSTALL_DIR/xtensa-lx106-elf/bin:\$PATH${GREEN} at the beginning of each session.${NC}\n";
	if [[ ":$PATH:" == *":$ESP_INSTALL_DIR/xtensa-lx106-elf/bin:"* ]]; then
		printf "${GREEN} > ${YELLOW}$ESP_INSTALL_DIR/xtensa-lx106-elf/bin${GREEN} is already in \$PATH.${NC}\n"
	else
		export PATH=$ESP_INSTALL_DIR/xtensa-lx106-elf/bin:$PATH;
	fi
}

if [[ -d $ESP_INSTALL_DIR/xtensa-lx106-elf/bin ]]; then
	ask question answer_yes answer_no
fi

# # Ask if you want to abbreviate Xtensa compiler to "xgcc"
# if [[ -d $ESP_INSTALL_DIR/xtensa-lx106-elf/bin ]]; then
# 	ask \
# 		"${GREEN} > Do you wish to abbreviate ${YELLOW}xtensa-lx106-elf-gcc${GREEN} to ${YELLOW}xgcc${GREEN}?${NC}" \
# 		"sudo echo \"# Xtensa abbreviation\" >> ~/.profile && sudo echo \"alias xgcc=\\\"xtensa-lx106-elf-gcc\\\"\" >> ~/.profile && sudo echo \"alias xg++=\\\"xtensa-lx106-elf-g++\\\"\" >> ~/.profile && echo \"\" >> ~/.profile"
# fi

# Ask if user wants to be added to dialout
function question { printf "${GREEN} > Do you wish to be added to ${YELLOW}dialout${GREEN} group?${NC}"; }
function answer_yes { sudo adduser $(whoami) dialout; }
if id -nG $(whoami) | grep -qw "dialout"; then
	printf "${GREEN} > ${YELLOW}$(whoami)${GREEN} is already in dialout group.${NC}\n"
else
	ask question answer_yes
fi
