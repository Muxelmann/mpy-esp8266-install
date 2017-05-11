#!/bin/bash

# Defining bash coloring
RED='\033[0;31m'
DARK_GREEN='\033[0;32m'
GREEN='\033[1;32m'
BROWN='\033[0;33m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Defining ESP dependencies that need to be installed
ESP_DEPENDENCIES="\
libtool-bin git build-essential make unrar-free autoconf automake libtool \
gcc g++ gperf flex bison texinfo gawk ncurses-dev libexpat-dev python-dev \
python python-serial sed git unzip bash help2man wget bzip2 picocom libffi-dev"

# Defining ESP GitHub repo address
ESP_GIT="https://github.com/pfalcon/esp-open-sdk.git"
ESP_SDK_DIR="esp-open-sdk"

# Defining Micropython GitHub repo address
MPY_GIT="https://github.com/micropython/micropython.git"
MPY_DIR="micropython"

# Simple function that allows easy "asking for permission"
function ask {
	# Print message
	$1; printf " (y/n)";
	while true; do
		read -p " " yn
		case $yn in
			[Yy]* ) $2; break ;;
			[Nn]* )
			if [ -n "$3" ]; then $3; fi
			break ;;
			* ) printf "Please enter \"y\" or \"n\"." ;;
		esac
	done
}
