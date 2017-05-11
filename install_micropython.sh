#!/bin/bash

source config.sh

INSTALL=1

for i in "$@"
do
case $i in
		-m=*|--mpy_sdk_dir=*)
		MPY_DIR="${i#*=}"
		shift # past argument=value
		;;
		-u|--update)
		INSTALL=0
		shift # past argument with no value
		;;
		-r|--recompile)
		INSTALL=2
		shift # past argument with no value
		;;
		-h|--help)
		cat .help_micropython
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
if [[ $INSTALL == 1 ]]; then # Install
	printf "${GREEN} > Installing Micropython (into ${MPY_DIR})${NC}\n"
	if [[ -d $MPY_DIR ]]; then
		printf "${GREEN} > Micropython directory already found (consider updating with \"-u\" instead)${NC}\n"
	else
		git clone $MPY_GIT $MPY_DIR
		cd $MPY_DIR
		git submodule update --init
		make -C mpy-cross
		cd esp8266
		make axtls
		make
		cd ../../
	fi
elif [[ $INSTALL == 2 ]]; then # Recompile
	if [[ -d $MPY_DIR ]]; then
		cd $MPY_DIR
		git submodule update --init
		make -C mpy-cross
		cd esp8266
		make axtls
		make
		cd ../../
	fi
else # Update
	if [[ -d $MPY_DIR ]]; then
		sudo rm -r $MPY_DIR
	fi
	git clone $MPY_GIT $MPY_DIR
	cd $MPY_DIR
	git submodule update --init
	make -C mpy-cross
	cd esp8266
	make axtls
	make
	cd ../../
fi

# Ask if unix port should be built
function question { printf "${GREEN} > Do you want to build the unix port?${NC}"; }
function answer_yes { cd $MPY_DIR/unix; make axtls && make; cd ../../; }
ask question answer_yes

# Ask if the firmware should be flashed
MPY_FW=$MPY_DIR/esp8266/build/firmware-combined.bin

function question { printf "${GREEN} > Do you want to flash the firmware?${NC}"; }
function answer_yes { esptool.py --port /dev/ttyUSB0 erase_flash && esptool.py --port /dev/ttyUSB0 --baud 230400 write_flash --flash_size detect --verify 0 ${MPY_FW}; }

if [[ -f $MPY_FW ]]; then
	ask question answer_yes
else
	printf "${RED} > Firmware not found at ${YELLOW}$MPY_FW${RED}!${NC}\n"
fi
