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
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
SERVER=$1
CONFIG=~/.connection_ref
TMP_FILE=/tmp/connection_script_$$.tmp
SSH_CMD="ssh "

touch ${TMP_FILE}

OLDIFS=$IFS
IFS=";"
I=0
while read L_DNS L_IP L_PORT L_USER L_KEYFILE;do
        if [ $(echo ${L_DNS} | grep -c ${SERVER}) -eq 0 ]; then
                continue
        fi
        I=$((${I} + 1))
        if [ ${I} -eq 1 ]; then
                echo -e "${JAUNE}${I} - ${L_IP} ${L_DNS}${NORMAL}"
        else
                echo ${I} - ${L_IP} ${L_DNS}
        fi
        echo "${L_DNS};${L_IP};${L_PORT};${L_USER};${L_KEYFILE}" >> ${TMP_FILE}
done < ${CONFIG}
IFS=$OLDIFS

while read L_IP L_DNS;do
        if [ $(echo ${L_DNS} | grep -c ${SERVER}) -eq 0 ]; then
                continue
        fi
        I=$((${I} + 1))
        if [ ${I} -eq 1 ]; then
                echo -e "${JAUNE}${I} - ${L_IP} ${L_DNS}${NORMAL}"
        else
                echo ${I} - ${L_IP} ${L_DNS}
        fi
        echo "${L_DNS};${L_IP};22;root;;" >> ${TMP_FILE}
done < /etc/hosts

if [ $I -eq 0 ]; then
        echo -e "${ROUGE}No system found${NORMAL}"
        exit 0
fi

echo "Number ? default is 1"
NUM=1
read NUM
if [ "$NUM" = "" ] ; then
        NUM=$SEL
fi

LINE=$(sed -n "${NUM}p" ${TMP_FILE})

S_DNS=$(echo ${LINE} | cut -d \; -f 1)
S_IP=$(echo ${LINE} | cut -d \; -f 2)
S_PORT=$(echo ${LINE} | cut -d \; -f 3)
S_USER=$(echo ${LINE} | cut -d \; -f 4)
S_KEYFILE=$(echo ${LINE} | cut -d \; -f 5)

if [ -z ${S_USER} ]; then
        S_USER=root
fi
if [ -z ${S_PORT} ]; then
        S_PORT=22
fi
OPTS=''
if [ ! -z ${S_KEYFILE} ]; then
        OPTS="${OPTS} -i ${S_KEYFILE}"
fi
OPTS="${OPTS} ${S_USER}@${S_IP}"
OPTS="${OPTS} -p ${S_PORT}"

echo -e "Connection on ${VERT}${S_DNS}${NORMAL} (IP : ${VERT}${S_IP}${NORMAL}:${VERT}${S_PORT}${NORMAL}) with user ${VERT}${S_USER}${NORMAL}"

${SSH_CMD} ${OPTS}
