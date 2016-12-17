#!/bin/bash
###################################
rsync_src=${1}
rsync_cib=${2}

echo -n "Copie de ${rsync_src} vers ${rsync_cib}... "

ssh_src=$(echo ${rsync_src} | grep -c "@")
ssh_cib=$(echo ${rsync_cib} | grep -c "@")

if [ ${ssh_src} -eq  0 ]; then
    if   ! [ -d ${rsync_src} ] && ! [ -f ${rsync_src} ]; then
            echo "Repertoire source ou fichier introuvable"
            exit 1
    fi

    if [ `find ${rsync_src} -type f | wc -l` -eq 0 ] ; then
            echo "Repertoire source vide"
            exit 1
    fi
fi

if [ ${ssh_cib} -eq  0 ]; then
    if ! [ -d ${rsync_cib} ]; then
            echo "Repertoire cible introuvable"
            exit 1
    fi

    if ! [ -r ${rsync_cib} ]; then
            echo "Repertoire illisible"
            exit 1
    fi

    if ! [ -w ${rsync_cib} ]; then
            echo "Repertoire non modifiable"
            exit 1
    fi
fi

rsync -rltgoDphv --force --delete-after --no-perms --no-owner --no-group  ${rsync_src} ${rsync_cib} >> /dev/null
code_retour=$?
if [ ${code_retour}  -ne 0 ] ; then
    echo "rsync error : "${code_retour}
        exit 1
fi;
echo "OK"
exit 0
