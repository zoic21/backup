#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TMPFILE=/tmp/con_$$_tmp.txt
TMPFILEO=/tmp/con_$$_tmpO.txt
if [ -f ${DIR}/username ];then
        USER=$(cat ${DIR}/username)
fi
if [ -z "${USER}" ];then
        USER='root'
fi

trap 'echo "Exiting.."; rm -f "TMPFILEO" "$TMPFILE" "$TMPFILE2" >/dev/null 2>&1 ;exit 2' 0 2

if [ "$1" = "" ] ; then
        echo "Entrez un nom de host"
        read IN
else
        IN=$1
fi
grep -i $IN /etc/hosts | grep -vE "w[   ]|s[    ]|w$|s$" > $TMPFILE
if [ -f ${DIR}/dns ];then
        grep -i $IN ${DIR}/dns   > $TMPFILEO
else
        touch $TMPFILEO
fi

NB=$(cat $TMPFILE  $TMPFILEO | wc -l)
if [ "$NB" = "0" ] ; then
        echo "no servers found for $IN"
        exit 1
fi

SEL=$(grep -nE "m[      ]|m$" $TMPFILEO | head -1 | cut -d: -f1)
if [ "$SEL"="" ]; then
        SEL=1
fi
echo "$NB servers found : "
cat $TMPFILEO | awk '
BEGIN { l=1; lineS='$SEL' }
{
        if ( l == lineS ) { printf "%c[33m",27 ; }
        printf "%s - %s", l, $0 ;
        if ( l == lineS ) { printf "%c[0m",27 ; }
        printf "\n";
        l++
}'
echo "Quel systeme ? default : $SEL "
read NUM
if [ "$NUM" = "" ] ; then
        NUM=$SEL
fi

SSH_CMD_USER="ssh "

HOST=$(sed -n "${NUM}p" $TMPFILEO | awk '{ print $2 }')
IP=$HOST
KEY=""
if [ $(grep $HOST ${DIR}/dns | wc -l) -ne 0 ]; then
        IP=$(awk -v dest=$HOST '$2 == dest { print $1 ; }' ${DIR}/dns)
fi

if [ -f ${DIR}/key ];then
        $SSH_CMD_USER -i ${DIR}/key -l ${USER}@${IP}
else
        $SSH_CMD_USER ${USER}@${IP}
fi

rm "$TMPFILEO"  2>/dev/null