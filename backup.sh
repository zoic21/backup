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

date=$(date +%d-%m-%Y_%H:%M:%S)
error=0
mailContent=''
repCourant=$(dirname $0)
hostname=$(hostname)
ftp=${ftp-0}
ldap=${ldap-0}
mysql=${mysql-0}
chown=${chown-0}
archive=${archive-0}
debug=${debug-0}

CONFIG_FILE=${1}
if [[ -f $CONFIG_FILE ]]; then
        . $CONFIG_FILE
else
        echo -e "[$(date +%d-%m-%Y\ %H:%M:%S)] ${ROUGE}Aucun fichier de configuration trouve${NORMAL}";
        exit 1
fi

echo  "-----------------------------------------------------------" >> ${report_log}
echo "[$(date +%d-%m-%Y\ %H:%M:%S)] Début du backup" >> ${report_log}
echo -e "[$(date +%d-%m-%Y\ %H:%M:%S)] ${BLEU}Début du backup${NORMAL}"
###################################################Backup des repertoires###################################################
for i in "${!src_dir[@]}"; do
        echo -n -e "[$(date +%d-%m-%Y\ %H:%M:%S)] Sauvegarde de ${JAUNE}${src_dir[$i]}${NORMAL} vers ${JAUNE}${cib_dir}${NORMAL}... "
        stdout=$(${repCourant}/backup_dir.sh ${src_dir[$i]} ${cib_dir})
        if [ $? -ne 0 ]; then
                echo -e "[$(date +%d-%m-%Y\ %H:%M:%S)] ${ROUGE}ECHEC${NORMAL} => ${CYAN}${stdout}${NORMAL}";
                echo "[$(date +%d-%m-%Y\ %H:%M:%S)] ${stdout}" >> ${report_log}
                mailContent=${mailContent}"\n[$(date +%d-%m-%Y\ %H:%M:%S)] Echec du backup de ${src_dir[$i]} vers ${cib_dir} : ${stdout}"
                error=1
        else
                echo "[$(date +%d-%m-%Y\ %H:%M:%S)] Backup de ${src_dir[$i]} dans  ${cib_dir} OK" >> ${report_log}
                echo -e "[$(date +%d-%m-%Y\ %H:%M:%S)] ${VERT}OK${NORMAL}"
                if [ ${debug} -ne 0 ] ; then
                        echo ${stdout} >> ${report_log}
                        echo -e ${CYAN}${stdout}${NORMAL}
                fi
        fi
done

########################################################Backup LDAP########################################################
if [ ${ldap} -ne 0 ] ; then
        echo -n -e "[$(date +%d-%m-%Y\ %H:%M:%S)] Backup ${JAUNE}LDAP${NORMAL}... "
        if [ ! -e ${cib_dir}/LDAP ]; then
                mkdir ${cib_dir}/LDAP
        fi
        stdout=$(/usr/sbin/slapcat -v -b ${ldap_basedn} -l ${cib_dir}/LDAP/ldap-${date}.ldif 2>&1)
        if [ $? -ne 0 ]; then
                error=1
                mailContent=${mailContent}"\n[$(date +%d-%m-%Y\ %H:%M:%S)] Backup LDAP ECHEC : ${stdout}"
                echo "[$(date +%d-%m-%Y\ %H:%M:%S)] Backup LDAP ECHEC : ${stdout}" >> ${report_log}
                echo -e "[$(date +%d-%m-%Y\ %H:%M:%S)] ${ROUGE}ECHEC${NORMAL} : ${CYAN}${stdout}${NORMAL}"
        else
                find ${cib_dir}/LDAP -mtime +${ldap_keep_day} -print | xargs -r rm
                echo "[$(date +%d-%m-%Y\ %H:%M:%S)] Backup LDAP OK" >> ${report_log}
                echo -e "[$(date +%d-%m-%Y\ %H:%M:%S)] ${VERT}OK${NORMAL}"
                if [ ${debug} -ne 0 ] ; then
                        echo ${stdout} >> ${report_log}
                        echo -e ${CYAN}${stdout}${NORMAL}
                fi
        fi
fi

########################################################Backup MySQL########################################################
if [ ${mysql} -ne 0 ] ; then
        echo -n -e "[$(date +%d-%m-%Y\ %H:%M:%S)] Backup ${JAUNE}MySQL${NORMAL}... "
        if [ ! -e ${cib_dir}/MySQL ]; then
                mkdir ${cib_dir}/MySQL
        fi
        stdout=$(${repCourant}'/'backup_MySQL.sh ${mysql_user} ${mysql_password} ${mysql_host}  ${cib_dir}/MySQL 2>&1)
        if [ $? -ne 0 ]; then
                error=1
                mailContent=${mailContent}"\n[$(date +%d-%m-%Y\ %H:%M:%S)] Backup MySQL ECHEC : ${stdout}"
        echo "[$(date +%d-%m-%Y\ %H:%M:%S)] Backup MySQL ECHEC : ${stdout}" >> ${report_log}
                echo -e "[$(date +%d-%m-%Y\ %H:%M:%S)] ${ROUGE}ECHEC${NORMAL} : ${CYAN}${stdout}${NORMAL}"
        else
                find ${cib_dir}/MySQL -mtime +${mysql_keep_day} -print | xargs -r rm
                echo "[$(date +%d-%m-%Y\ %H:%M:%S)] Backup MySQL OK" >> ${report_log}
                echo -e "[$(date +%d-%m-%Y\ %H:%M:%S)] ${VERT}OK${NORMAL}"
                if [ ${debug} -ne 0 ] ; then
                        echo ${stdout} >> ${report_log}
                        echo -e ${CYAN}${stdout}${NORMAL}
                fi
        fi
fi

########################################################Chown########################################################
if [ ${chown} -ne 0 ] ; then
        echo -n -e "[$(date +%d-%m-%Y\ %H:%M:%S)] Mise à jour des droit sur ${JAUNE}${cib_dir}${NORMAL}... "
        stdout=$(chown ${chown_user}:${chown_group} -R ${cib_dir} 2>&1)
        if [ $? -ne 0 ]; then
                error=1
                mailContent=${mailContent}"\n[$(date +%d-%m-%Y\ %H:%M:%S)] ECHEC : ${stdout}"
                echo "[$(date +%d-%m-%Y\ %H:%M:%S)] Mise à jour des droits ${cib_dir} ECHEC : ${stdout}" >> ${report_log}
                echo -e "[$(date +%d-%m-%Y\ %H:%M:%S)] ${ROUGE}ECHEC${NORMAL} :  ${CYAN}${stdout}${NORMAL}"
        else
                echo "[$(date +%d-%m-%Y\ %H:%M:%S)] Mise à jour des droits ${cib_dir} OK" >> ${report_log}
                echo -e "[$(date +%d-%m-%Y\ %H:%M:%S)] ${VERT}OK${NORMAL}"
                if [ ${debug} -ne 0 ] ; then
                        echo ${stdout} >> ${report_log}
                        echo -e ${CYAN}${stdout}${NORMAL}
                fi
        fi
fi

########################################################Envoi FTP########################################################
if [ ${ftp} -ne 0 ] ; then
        echo -n -e "[$(date +%d-%m-%Y\ %H:%M:%S)] Envoi sur le serveur ${JAUNE}FTP${NORMAL}... "
        ftp_keep_day=${ftp_keep_day-9999}
        ftp_dir=${ftp_dir-""}
        ftp_name=${ftp_name-$(hostname)}

        stdout=$(${repCourant}/backup_ftp.sh ${ftp_server} ${ftp_user} ${ftp_password} ${cib_dir} ${ftp_tmp} ${ftp_keep_day} ${ftp_name} ${ftp_dir} 2>&1)
        if [ $? -ne 0 ]; then
                error=1
                mailContent=${mailContent}"\n[$(date +%d-%m-%Y\ %H:%M:%S)] Envoi FTP ECHEC : ${stdout}"
                echo "[$(date +%d-%m-%Y\ %H:%M:%S)] Envoie FTP ECHEC : ${stdout}" >> ${report_log}
                echo -e "[$(date +%d-%m-%Y\ %H:%M:%S)] ${ROUGE}ECHEC${NORMAL} : ${CYAN}${stdout}${NORMAL}"
        else
                echo "[$(date +%d-%m-%Y\ %H:%M:%S)] Envoie FTP OK" >> ${report_log}
                echo -e "[$(date +%d-%m-%Y\ %H:%M:%S)] ${VERT}OK${NORMAL}"
                if [ ${debug} -ne 0 ] ; then
                        echo ${stdout} >> ${report_log}
                        echo -e ${CYAN}${stdout}${NORMAL}
                fi
        fi
fi

if [ ${samba} -ne 0 ] ; then
        echo -n -e "[$(date +%d-%m-%Y\ %H:%M:%S)] Envoi sur le serveur ${JAUNE}SAMBA${NORMAL}... "
        samba_keep_day=${ftp_samba_day-9999}
        samba_dir=${samba_dir-""}
        samba_name=${samba_name-$(hostname)}

        stdout=$(${repCourant}/backup_samba.sh ${samba_server} ${samba_user} ${samba_password} ${cib_dir} ${samba_tmp} ${samba_keep_day} ${samba_name} ${samba_dir} ${samba_share} 2>&1)
        if [ $? -ne 0 ]; then
                error=1
                mailContent=${mailContent}"\n[$(date +%d-%m-%Y\ %H:%M:%S)] Envoi FTP ECHEC : ${stdout}"
                echo "[$(date +%d-%m-%Y\ %H:%M:%S)] Envoie SAMBA ECHEC : ${stdout}" >> ${report_log}
                echo -e "[$(date +%d-%m-%Y\ %H:%M:%S)] ${ROUGE}ECHEC${NORMAL} : ${CYAN}${stdout}${NORMAL}"
        else
                echo "[$(date +%d-%m-%Y\ %H:%M:%S)] Envoie FTP OK" >> ${report_log}
                echo -e "[$(date +%d-%m-%Y\ %H:%M:%S)] ${VERT}OK${NORMAL}"
                if [ ${debug} -ne 0 ] ; then
                        echo ${stdout} >> ${report_log}
                        echo -e ${CYAN}${stdout}${NORMAL}
                fi
        fi
fi


########################################################Archivage########################################################
if [ ${archive} -ne 0 ] ; then
        archive_name=${archive_name-$(hostname)}
        echo -n -e "[$(date +%d-%m-%Y\ %H:%M:%S)] ${JAUNE}Archivage${NORMAL}... "
        stdout=$(tar cf ${archive_cib_dir}/${archive_name}_$(date +%d-%m-%Y_%H:%M:%S).tar ${cib_dir} 2>&1)
        if [ $? -ne 0 ]; then
                error=1
                mailContent=${mailContent}"\n[$(date +%d-%m-%Y\ %H:%M:%S)] Archivage ECHEC : ${stdout}"
                echo "[$(date +%d-%m-%Y\ %H:%M:%S)] Archivage ECHEC : ${stdout}" >> $report_log
                echo -e "[$(date +%d-%m-%Y\ %H:%M:%S)] ${ROUGE}ECHEC${NORMAL} : ${CYAN}${stdout}${NORMAL}"
        else
                find ${archive_cib_dir} -mtime +${archive_keep_day} -print | xargs -r rm
                echo -e "[$(date +%d-%m-%Y\ %H:%M:%S)] ${VERT}OK${NORMAL}"
                if [ ${debug} -ne 0 ] ; then
                        echo ${stdout} >> ${report_log}
                        echo -e ${CYAN}${stdout}${NORMAL}
                fi
        fi
fi

########################################################Envoie mail########################################################
if [ $error -ne 0 ]; then
        echo "[$(date +%d-%m-%Y\ %H:%M:%S)] Backup finis avec erreur" >> $report_log
        echo -n "[$(date +%d-%m-%Y\ %H:%M:%S)] Il y a eu des erreurs envoi du mail alerte... "
        echo -e "${mailContent}"| mail -s "Backup en erreur sur ${hostname} le $(date)" ${mail}
        echo -e "[$(date +%d-%m-%Y\ %H:%M:%S)] ${VERT}OK${NORMAL}"
        echo -e "[$(date +%d-%m-%Y\ %H:%M:%S)] ${ROUGE}Echec du backup${NORMAL}"
else
        echo "[$(date +%d-%m-%Y\ %H:%M:%S)] Backup réussi" >> $report_log
        echo -e "[$(date +%d-%m-%Y\ %H:%M:%S)] ${VERT}Backup réussi${NORMAL}"
fi
