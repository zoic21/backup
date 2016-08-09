#!/bin/bash
samba_ip=${1}
samba_username=${2}
samba_password=${3}
cib_dir=${4}
tmp_dir=${5}
samba_dir=${8}
samba_filename=${7-$(hostname)}
samba_share=${9}

date=$(date +%Y-%m-%d)
date_remove=$(date --date "${6} days ago" +%Y-%m-%d)

if [ ! -d $tmp_dir ]; then
  mkdir -p $tmp_dir
  if [ $? -ne 0 ]; then
        echo "Impossible de creer le dossier temporaire : ${tmp_dir}"
    exit 1
   fi
fi

echo -n "Création du l'archive... "
tar -czf ${tmp_dir}/${samba_filename}-${date}.tar.gz ${cib_dir}
if [ $? -ne 0 ]; then
        echo "Impossible de ceer le TAR"
    exit 1
fi
echo 'OK'

smbclient ${samba_share} -U ${samba_username}%${samba_password} -I ${samba_ip} -c "cd ${samba_dir}; put ${tmp_dir}/${samba_filename}-${date}.tar.gz"
if [ $? -ne 0 ]; then
        echo "Impossible de sauvegarder sur le Samba"
        exit 1
fi
echo 'OK'

smbclient ${samba_share} -U ${samba_username}%${samba_password} -I ${samba_ip} -c "cd ${samba_dir}; delete ${samba_filename}-${date_remove}.tar.gz"

if [ $? -ne 0 ]; then
        echo "Impossible de sauvegarder sur Samba"
        exit 1
fi
echo 'OK'

echo -n "Supression de l'archive... "
rm -rf ${tmp_dir}
if [ $? -ne 0 ]; then
        echo "Impossible de supprimer le dossier temporaire : ${tmp_dir}"
        exit 1
fi
echo 'OK'

exit 0
