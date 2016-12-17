#!/bin/bash
ftp_server=${1}
ftp_login=${2}
ftp_pass=${3}
cib_dir=${4}
tmp_dir=${5}
ftp_dir=${8}
ftp_filename=${7-$(hostname)}

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
tar -czf ${tmp_dir}/${ftp_filename}-${date}.tar.gz ${cib_dir}
if [ $? -ne 0 ]; then
        echo "Impossible de ceer le TAR"
    exit 1
fi
echo 'OK'

echo -n "Envoie sur le FTP... "
ftp -n $ftp_server <<END
        passive
        user ${ftp_login} ${ftp_pass}
        put ${tmp_dir}/${ftp_filename}-${date}.tar.gz ${ftp_dir}
        delete ${ftp_filename}-${date_remove}.tar.gz
        quit
END

if [ $? -ne 0 ]; then
        echo "Impossible de sauvegarder sur le FTP"
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
