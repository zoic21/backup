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
CMD=$2
CONFIG=~/.connection_ref
TMP_FILE=/tmp/connection_script_$$.tmp
TMP_FILE2=/tmp/connection_script_$$2.tmp
TMP_MSSH_FILE=/tmp/connection_mssh_$$2.tmp

touch ${TMP_FILE}
touch ${TMP_FILE2}

OLDIFS=$IFS
IFS=";"
I=0
while read L_DNS L_IP L_PORT L_USER L_KEYFILE;do
        if [ $(echo ${L_DNS} | grep -c -i ${SERVER}) -eq 0 ]; then
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
        if [ $(echo ${L_DNS} | grep -c -i ${SERVER}) -eq 0 ]; then
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

DNSASK=$(getent hosts ${SERVER} | awk '{print $1}')
if [ ! -z ${DNSASK} ]; then
        if [ $(grep -c -i ${DNSASK} ${TMP_FILE}) -eq 0 ]; then
                I=$((${I} + 1))
                if [ ${I} -eq 1 ]; then
                        echo -e "${JAUNE}${I} - ${DNSASK} ${SERVER}${NORMAL}"
                else
                        echo ${I} - ${DNSASK} ${SERVER}
                fi
                echo "${SERVER};${DNSASK};22;root;;" >> ${TMP_FILE}
        fi
fi

if [ $I -eq 0 ]; then
        echo -e "${ROUGE}No system found${NORMAL}"
        exit 0
fi

echo "Number ? default is 1"
NUMS=1
read SEL
if [ ! -z ${SEL} ] ; then
        NUMS=${SEL}
fi

if [ ! -f "${CMD}" ]; then
        echo ${CMD} > ${TMP_MSSH_FILE}
else
        TMP_MSSH_FILE=${CMD}
fi

if [ $(echo ${NUMS} | grep -c ';') -eq 0 ];then
        sed -n "${NUMS}p" ${TMP_FILE} >> ${TMP_FILE2}
else
        for NUM in $(echo ${NUMS} | tr ";" "\n"); do
                sed -n "${NUM}p" ${TMP_FILE} >> ${TMP_FILE2}
        done
fi
IFS=';'
while read -u10 S_DNS S_IP S_PORT S_USER S_KEYFILE;do
        if [ -z ${S_IP} ];then
                continue
        fi
        if [ -z ${S_USER} ]; then
                S_USER=root
        fi
        if [ -z ${S_PORT} ]; then
                S_PORT=22
        fi
        OPTS=''
        if [ ! -z ${S_KEYFILE} ]; then
                OPTS="${OPTS} -i ${S_KEYFILE} "
        fi
        OPTS="${OPTS}${S_USER}@${S_IP} "
        OPTS="${OPTS}-p ${S_PORT}"
        if [ -z ${CMD} ]; then
                echo -e "Connection on ${VERT}${S_DNS}${NORMAL} (IP : ${VERT}${S_IP}${NORMAL}:${VERT}${S_PORT}${NORMAL}) with user ${VERT}${S_USER}${NORMAL}"
                if [ ! -z ${S_KEYFILE} ]; then
                        ssh -i ${S_KEYFILE} ${S_USER}@${S_IP} -p ${S_PORT}
                else
                        ssh ${S_USER}@${S_IP} -p ${S_PORT}
                fi
        else
                echo -e "Command ${VERT}${CMD}${NORMAL} on ${VERT}${S_IP}${NORMAL}:${VERT}${S_PORT}${NORMAL} with user ${VERT}${S_USER}${NORMAL}"
                OPTS_SCP=''
                if [ ! -z ${S_KEYFILE} ]; then
                        scp  -q ${S_KEYFILE} ${TMP_MSSH_FILE} ${S_USER}@${S_IP}:${TMP_MSSH_FILE} > /dev/null
                else
                        scp ${TMP_MSSH_FILE} ${S_USER}@${S_IP}:${TMP_MSSH_FILE} > /dev/null
                fi
                if [ $? -eq 0 ]; then
                        if [ ! -z ${S_KEYFILE} ]; then
                                ssh -n -x -i ${S_KEYFILE} ${S_USER}@${S_IP} -p ${S_PORT} "bash ${TMP_MSSH_FILE};rm ${TMP_MSSH_FILE}"
                        else
                                ssh -n -x ${S_USER}@${S_IP} -p ${S_PORT} "bash ${TMP_MSSH_FILE};rm ${TMP_MSSH_FILE}"
                        fi
                else
                        echo -e "${ROUGE} Error on file transfert ${NORMAL}"
                fi
        fi
done 10< ${TMP_FILE2}

rm ${TMP_FILE} ${TMP_FILE2}
IFS=$OLDIFS
exit 0
