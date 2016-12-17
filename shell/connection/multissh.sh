#!/bin/bash
VERT="\\033[1;32m"
NORMAL="\\033[0;39m"
ROUGE="\\033[1;31m"
ROSE="\\033[1;35m"
BLEU="\\033[1;34m"
BLANC="\\033[0;02m"
BLANCLAIR="\\033[1;08m"
JAUNE="\\033[1;33m"
CYAN="\\033[1;36m"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

SSH_USER=$(id -u -n)
FILE_LIST_SERVER=''
FILE_CMD=''
FILE_SSHKEY=''
MSUID=$$
DNS='no'
EXEC_USER=''

if [ -f /tmp/multishell${MSUID}_cmd.sh ]; then
	rm /tmp/multishell${MSUID}_cmd.sh
fi
if [ -f /tmp/multishell${MSUID}_server ]; then
	rm /tmp/multishell${MSUID}_server
fi

if [ "$1" = "-h" -o "$1" = "help" ]; then
	echo "Usage $0 -s <host> -s <host> -c <cmd> [-d yes] [-u <sshuser>] [-k <file ssh key>]"
	echo "	-s <host> : hostname or alias (if -d option), you can add much as you want"
	echo "	-c <cmd> : command to execute"
	echo "	-d yes : enable DNS research and replace (alias)"
	echo "	-u <sshuser> : to change username for ssh connection"
	echo "	-e <executeuser> : to change user who execute command"
	echo "	-k <file ssh key> : specify another key file"
	echo "Usage $0 -s <host_file> -c <cmd_dile> [-d yes] [-u <sshuser] [-k <file ssh key>]"
	echo "	-s <host_file> : list of hosts, you can add arg for command"
	echo "		server1 arg1 arg2"
	echo "		server1 arg3 arg2"
	echo "	-c <cmd_dile> : file with command to execute, ex : "
	echo '		echo $1'
	echo '		VAR1=$2'
	echo '		echo ${VAR1}'
	exit 0
fi

while getopts ":c:s:u:k:d:e:" opt; do
  case $opt in
    c) FILE_CMD="$OPTARG"
    ;;
    s) if [ ! -f "${OPTARG}" ]; then
	   		echo ${OPTARG} >> /tmp/multishell${MSUID}_server
			FILE_LIST_SERVER="/tmp/multishell${MSUID}_server"
	   else
	   		FILE_LIST_SERVER="$OPTARG"
	   fi
    ;;
    u) SSH_USER="$OPTARG"
    ;;
    e) EXEC_USER="$OPTARG"
    ;;
    k) FILE_SSHKEY="$OPTARG"
    ;;
    d) DNS='yes'
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

if [ -z ${FILE_LIST_SERVER} ]; then
	echo 'File server can not be empty'
	exit
fi

if [ ! -f "${FILE_LIST_SERVER}" ]; then
	echo 'File server does not exist : '${FILE_LIST_SERVER}
	exit
fi

if [ ! -f "${FILE_CMD}" ]; then
	echo ${FILE_CMD} > /tmp/multishell${MSUID}_cmd.sh
	FILE_CMD="/tmp/multishell${MSUID}_cmd.sh"
fi

if [ ! -z ${FILE_SSHKEY} ]; then
	if [ ! -f "${FILE_SSHKEY}" ]; then
		echo 'SSH key file does not exist'
		exit
	fi
fi

if [ "${DNS}" = "yes" ];then
	TMPFILE=/tmp/multissh_${MSUID}_con.txt
	FILE_LIST_SERVER_TMP=${FILE_LIST_SERVER}_${MSUID}_tmp
	if [ -f ${FILE_LIST_SERVER_TMP} ]; then
		rm ${FILE_LIST_SERVER_TMP}
	fi
	while read SERVER ARGS;do 
		if [ -f "$TMPFILE" ]; then
			rm $TMPFILE
		fi
		grep -i ${SERVER} /etc/hosts | grep -vE "w[   ]|s[    ]|w$|s$" >> ${TMPFILE}
		if [ -f "${DIR}/dns" ]; then
			grep -i ${SERVER} ${DIR}/dns  >> ${TMPFILE}
		fi
		SERVER_TMP=$(grep ${SERVER} ${TMPFILE} | head -n 1 | awk '{ print $1 }')
		if [ ! -z ${SERVER_TMP} ]; then
			SERVER=${SERVER_TMP}
		fi
		echo "${SERVER} ${ARGS}" >> ${FILE_LIST_SERVER_TMP}
	done < ${FILE_LIST_SERVER}
	if [ -f "$TMPFILE" ]; then
			rm $TMPFILE
	fi
	FILE_LIST_SERVER=${FILE_LIST_SERVER_TMP}
fi

echo -e "--------------------------------------------CONFIG----------------------------------------------"

if [ -z ${EXEC_USER} ]; then
	echo -e "Username : ${JAUNE}${SSH_USER}${NORMAL}"
else
	echo -e "Username : ${JAUNE}${SSH_USER}${NORMAL} => ${VERT}${EXEC_USER}${NORMAL}"
fi
if [ ! -z ${FILE_SSHKEY} ]; then
	echo -e "Use ssh key file : ${JAUNE}${FILE_SSHKEY}${NORMAL}"
fi
echo -e "Server list :"
while read SERVER ARGS;do  
	echo -e "${JAUNE}${SERVER}${NORMAL}\c"
	if [ ! -z ${ARGS} ]; then
		echo -e " with args ${JAUNE}${ARGS}${NORMAL}"
	else
		echo ""
	fi
done < ${FILE_LIST_SERVER}

echo -e "Execute command : "
echo -e "${JAUNE}\c"
cat ${FILE_CMD}
echo -e "${NORMAL}\c"
echo -e "-----------------------------------------------------------------------------------------------"
read -p "Are you sure ? " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi
echo ""
SSH_KEYCMD=''
if [ ! -z ${FILE_SSHKEY} ]; then
	SSH_KEYCMD=' -i '${FILE_SSHKEY}
fi
while read SERVER ARGS;do  
	echo -e "-----------------------------------------------------------------------------------------------"
	if [ -z ${EXEC_USER} ]; then
		echo -e "Execute command on ${VERT}${SERVER}${NORMAL} with user ${VERT}${SSH_USER}${NORMAL}\c"
	else
		echo -e "Execute command on ${VERT}${SERVER}${NORMAL} with user ${VERT}${SSH_USER}${NORMAL} => ${VERT}${EXEC_USER}${NORMAL}\c"
	fi
	if [ ! -z ${ARGS} ]; then
		echo -e " and args ${VERT}${ARGS}${NORMAL}"
	else
		echo ""
	fi
	echo -e "-----------------------------------------------------------------------------------------------"
	echo ""
	scp -q ${SSH_KEYCMD} ${FILE_CMD} ${SSH_USER}@${SERVER}:/tmp/multishell${MSUID}.sh
	if [ $? -eq 0 ]; then
		if [ -z ${EXEC_USER} ]; then
			ssh -n -x ${SSH_KEYCMD} ${SSH_USER}@${SERVER} "bash /tmp/multishell${MSUID}.sh ${ARGS};rm /tmp/multishell${MSUID}.sh"
		else
			ssh -n -x ${SSH_KEYCMD} ${SSH_USER}@${SERVER} "su - ${EXEC_USER} -c \"bash /tmp/multishell${MSUID}.sh ${ARGS}\";rm /tmp/multishell${MSUID}.sh"
		fi
	else
		echo -e "${ROUGE} Error on file transfert ${NORMAL}"
	fi
	echo ""

done < ${FILE_LIST_SERVER}

if [ -f /tmp/multishell${MSUID}_cmd.sh ]; then
	rm /tmp/multishell${MSUID}_cmd.sh
fi
if [ -f /tmp/multishell${MSUID}_server ]; then
	rm /tmp/multishell${MSUID}_server
fi
if [ -z ${FILE_LIST_SERVER_TMP} -a -f ${FILE_LIST_SERVER_TMP} ];then
	rm ${FILE_LIST_SERVER_TMP}
fi
echo -e "-----------------------------------------------------------------------------------------------"
echo -e "${VERT}Done${NORMAL}"