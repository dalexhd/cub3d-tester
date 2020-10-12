#!/bin/bash

source setup.sh

function check_set_env
{
	COLUMNS=`tput cols`
	if [ "${COLUMNS}" == "" ]
	then
		COLUMNS=80
	fi
	DISK_USAGE="$(du -ms | awk '$2 == "." {print $1}')"
}


#CLEAR INITIAL TERMINAL WINDOW
clear
check_set_env

# Functions
function display_center
{
	local LEN MARGIN

	if [ "${1}" != "" ]
	then
		LEN=${#1}
		(( MARGIN= (${COLUMNS} - ${LEN}) / 2 ))
		printf "%"${MARGIN}"s" " "
		printf "${1}"
		(( MARGIN= ${MARGIN} + (${COLUMNS} - ${LEN} - ${MARGIN} * 2) ))
		printf "%"${MARGIN}"s\n" " "
	else
		printf "\n"
	fi
}

function display_leftandright
{
	local COLORLEFT="${1}" COLORCENTER="${2}" COLORRIGHT="${3}" TEXTLEFT="${4}" TEXTRIGHT="${5}" LEN

	LEN="$(( ${COLUMNS} - ${#TEXTLEFT} - ${#TEXTRIGHT} ))"
	if [ "${LEN}" -ge "0" ]
	then
		printf "${COLORLEFT}%s${COLORCENTER}% ${LEN}s${COLORRIGHT}%s${C_CLEAR}\n" "${TEXTLEFT}" " " "${TEXTRIGHT}"
	else
		printf "${COLORLEFT}%- ${COLUMNS}s\n${COLORRIGHT}% ${COLUMNS}s${C_CLEAR}\n" "${TEXTLEFT}" "${TEXTRIGHT}"
	fi
}
export -f display_leftandright

NO_LEAKS=0
PROCESS=2
SHOW_OUTPUT=0
i=1
while (( i <= $# ))
do
  case "${!i}" in
    "--process")
      (( i += 1 ))
      PROCESS="${!i}"
      ;;
    "--no-leaks") NO_LEAKS=1 ;;
    "--show-output") SHOW_OUTPUT=1 ;;
  esac
  (( i += 1 ))
done

ts=$(date +%s%N)

#WELCOME SCREEN + INSTRUCTIONS
display_center "+====================================+"
display_center "CUB3D TESTER"
display_center "LET'S BREAK YOUR PARSER!"
display_center "42 Madrid 2020"
display_center "By aborboll & dkrecisz"
display_center "+====================================+"
#Try to make cub3D
printf "\n${BHWHT}Attempting to make cub3D in parent directory...\n"
echo "$ make -C ../ &>/dev/null" && make -C ../ &>/dev/null

#Exit if make failed
if [[ $? -ne 0 ]]; then
	printf "\n${BYEL}${REDB} ${BHWHT} Error: Failed to make cub3D in parent directory! ${RESET}${BYEL}\n${RESET}"
	exit 1
fi

#COUNTER FOR PARSER DESTROYED/PASSED CASES
FAIL=0
OK=0

#LOGFILE FOR PARSER DESTROYED STUFF
log=report.log
out=tmp.txt
valgrind_out=valgrind_tmp.txt
date > $log && printf "\n\n%sCUB3D DESTROYER - DAMAGE REPORT%s\n\n" $div2 $div2 >> $log && echo >> $log

display_center "+================== START TESTING ==================+"

rm -rf tmp/*

function processInvalid() {
	source setup.sh
	function check_set_env
	{
		COLUMNS=`tput cols`
		if [ "${COLUMNS}" == "" ]
		then
			COLUMNS=80
		fi
		DISK_USAGE="$(du -ms | awk '$2 == "." {print $1}')"
	}
	check_set_env
	if [[ $1 ]]; then
		log=report.log
		out=tmp/tmp-$1.txt
		file="invalid_maps/$1"
		if [[ $2 -eq 0 ]]; then
			valgrind_out=tmp/valgrind_tmp-$1.txt
			valgrind --tool=memcheck --leak-check=full --leak-resolution=high --show-leak-kinds=all --track-origins=yes --verbose ../cub3D $file &>$valgrind_out &
			wait $! &>/dev/null
			VALGRIND_RET=$(cat $valgrind_out | grep "definitely lost:" | cut -d : -f 2 | cut -d b  -f 1 | tr -d " " | tr -d ",")
		fi
		../cub3D $file &>$out &
		while [ ! -f $out ]; do sleep 0.001; done
		# kill $! &>/dev/null
		wait $! 2>/dev/null
		RET=$?
		[ -s $out ]
		FILECHECK=$?
		grep -q "Error$" $out
		NUM=1
		if [[ $(whoami) -eq "runner" ]]; then
			NUM=0
		fi
		if [[ $? -ne $NUM || $FILECHECK -ne 0 || $RET -eq 139 || $VALGRIND_RET -ne 0 ]]; then
			if  [ -f $log ]; then
				FAIL=$(grep -c "DESTROYED STUFF" $log)
			else
				FAIL=0
			fi
			printf "%s[DESTROYED STUFF]%s\n" $div1 $div1 >> $log && ls $file >> $log && cat $file >> $log && printf "\n" >> $log
			printf "PARSER OUTPUT:\n" >> $log
			cat $out >> $log
			if [[ $VALGRIND_RET -ne 0 ]]; then
				display_leftandright "${RESET}" "" "${BRED}" "MAP: $file" "[LEAKS DETECTED]"
				cat $valgrind_out  >> $log
			elif [[ $RET -eq 139 ]]; then
				display_leftandright "${RESET}" "" "${BRED}" "MAP: $file" "[SEGFAULT]"
				echo "[139] Segmentation fault" >> $log
			elif [[ $FILECHECK -ne 0 ]]; then
				display_leftandright "${RESET}" "" "${BRED}" "MAP: $file" "[EMPTY]"
				echo "[EMPTY]" >> $log
			fi
			cat $out
			rm -f $out
			rm -f $valgrind_out
		else
			display_leftandright "${RESET}" "" "${BGRN}" "MAP: $file" "[OK]"
			rm -f $out
			rm -f $valgrind_out
		fi
	fi
}

function processValid() {
	source setup.sh
	function check_set_env
	{
		COLUMNS=`tput cols`
		if [ "${COLUMNS}" == "" ]
		then
			COLUMNS=80
		fi
		DISK_USAGE="$(du -ms | awk '$2 == "." {print $1}')"
	}
	check_set_env
	if [[ $1 ]]; then
		log=report.log
		out=tmp/tmp-$1.txt
		file="valid_maps/$1"
		VALGRIND_RET=0
		if [[ $2 -eq 0 ]]; then
			valgrind_out=tmp/valgrind_tmp-$1.txt
			valgrind --tool=memcheck --leak-check=full --leak-resolution=high --show-leak-kinds=all --track-origins=yes --verbose ../cub3D $file &>$valgrind_out &
			wait $! &>/dev/null
			VALGRIND_RET=$(cat $valgrind_out | grep "definitely lost:" | cut -d : -f 2 | cut -d b  -f 1 | tr -d " " | tr -d ",")
		fi
		../cub3D $file &>$out &
		while [ ! -f $out ]; do sleep 0.001; done
		# kill $! &>/dev/null
		wait $! 2>/dev/null
		RET=$?
		[ -s $out ]
		FILECHECK=$?
		grep -q "Error$" $out
		if [[ $RET -ne 0 || $VALGRIND_RET -ne 0 ]]; then
		# echo $VALGRIND_RET;
			if  [ -f $log ]; then
				FAIL=$(grep -c "DESTROYED STUFF" $log)
			else
				FAIL=0
			fi
			printf "\n%s[DESTROYED STUFF]%s\n" $div1 $div1 >> $log && ls $file >> $log && cat $file >> $log && printf "\n" >> $log
			printf "PARSER OUTPUT:\n" >> $log
			cat $out >> $log
			if [[ $VALGRIND_RET -ne 0 ]]; then
				display_leftandright "${RESET}" "" "${BRED}" "MAP: $file" "[LEAKS DETECTED]"
				cat $valgrind_out  >> $log
			elif [[ $RET -eq 139 ]]; then
				display_leftandright "${RESET}" "" "${BRED}" "MAP: $file" "[SEGFAULT]"
				echo "[139] Segmentation fault" >> $log
			elif [[ $FILECHECK -ne 0 ]]; then
				display_leftandright "${RESET}" "" "${BRED}" "MAP: $file" "[EMPTY]"
				echo "[EMPTY]" >> $log
			fi
			cat $out
			rm -f $out
			rm -f $valgrind_out
		else
			display_leftandright "${RESET}" "" "${BGRN}" "MAP: $file" "[OK]"
			rm -f $out
			rm -f $valgrind_out
		fi
	fi
}

export -f processInvalid
# ITERATE THROUGH INVALID MAPS
find ./invalid_maps/*.cub -type f -printf "%f\n" | xargs -n 1 -P $PROCESS -I {} bash -c 'processInvalid "$@" '$NO_LEAKS _ {}

# ITERATE THROUGH VALID MAPS
export -f processValid
find ./valid_maps/*.cub -type f -printf "%f\n" | xargs -n 1 -P $PROCESS -I {} bash -c 'processValid "$@" '$NO_LEAKS _ {}
rm -f $out

#OUTPUT FINAL RESULT
FAIL=$(grep -c "DESTROYED STUFF" $log)
invalid_mapcount=$(ls -1q ./invalid_maps/*.cub | wc -l)
valid_mapcount=$(ls -1q ./valid_maps/*.cub | wc -l)
OK=$((invalid_mapcount + valid_mapcount - FAIL))
tt=$((($(date +%s%N) - $ts)/1000000))
printf "\n${BBLU}%s${BWHT} FINAL RESULT ${BBLU}%s\n\n" $div1 $div1
printf "${BGRN}BULLETPROOF:\t%d\t\n" $OK
printf "${BRED}DESTROYED:\t%d \t\n" $FAIL
printf "${BBLU}TIME ELAPSED:\t%dms \t\n\n" $tt
printf "${BBLU}================== ${BWHT} REPORT.LOG CREATED ${BBLU} ===================${RESET}\n\n"
if [[ $SHOW_OUTPUT -eq 1 ]]; then
	cat $log
fi
if [[ $FAIL -gt 0]]
	exit 1
fi
