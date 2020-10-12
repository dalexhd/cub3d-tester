#!/bin/bash

#Regular bold text
BRED="\e[1;31m"
BGRN="\e[1;32m"
BYEL="\e[1;33m"
BBLU="\e[1;34m"
BWHT="\e[1;37m"

#Regular background
REDB="\e[41m"
YELB="\e[43m"

#High intensty text
HRED="\e[0;91m"
HYEL="\e[0;93m"
HWHT="\e[0;97m"

#High intensty background
YELHB="\e[0;103m"

#Bold high intensity text
BHYEL="\e[1;93m"
BHWHT="\e[1;97m"

RESET="\033[0m"
#PRINTING STUFF lol
div1="=========================="
div2="====================="
TEST_COL=67
RESULT_COL=87
TITLE_LENGTH=92
CHAR_LENGTH="-"
CHAR_WIDTH="|"
FILECHECKER_SH="1"
function check_set_env
{
	COLUMNS=`tput cols`
	if [ "${COLUMNS}" == "" ]
	then
		COLUMNS=80
	fi
	DISK_USAGE="$(du -ms | awk '$2 == "." {print $1}')"
}
