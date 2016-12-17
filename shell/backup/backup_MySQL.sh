#!/bin/bash

username=${1}
password=${2}
hostname=${3}
bckdir=${4}

#date du jour
date=$(date +%y-%m-%d_%H:%M:%S)

mysql -u${username} -p${password} -h ${hostname} -e exit 2>/dev/null
if [ $? -ne 0 ]; then
        echo 'Connection MySQL impossible'
        exit 1
fi

CODE_RETOUR=0

#liste des dossier
LISTEBDD=$( echo 'show databases' | mysql -u${username} -p${password} -h ${hostname} )

#on boucle sur chaque dossier (for découpe automatiquement par l'espace)
for SQL in $LISTEBDD ; do
        if [ ${SQL} != "information_schema" ] && [ ${SQL} != "mysql" ] && [ ${SQL} != "Database" ] && [ ${SQL} != "performance_schema" ]; then
                mysqldump --single-transaction -q -u${username} -p${password}  -h ${hostname} ${SQL} | gzip > ${bckdir}/${SQL}"-"${date}.sql.gz
                if [ $? -ne 0 ]; then
                        CODE_RETOUR=1
                fi
        fi
done

if [ ${CODE_RETOUR}  -ne 0 ]; then
        exit 1
fi
echo 'Backup MySQL OK'
exit 0
