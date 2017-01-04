#!/bin/sh

LOGIN=TODO
TOKEN=TODO
ORG=TODO
DONE=0
PAGE=0
DIR_BCK="/todo"

NUMREPOS=$(curl -s "https://$LOGIN:$TOKEN@api.github.com/orgs/$ORG" | awk '
   /public_repos/{t+=$2}
   /total_private_repos/{t+=$2}
   END{print t}')

echo "Num repos : ${NUMREPOS}"

while [ ${DONE} -lt ${NUMREPOS} ]; do
   for REPO in $(curl -s "https://$LOGIN:$TOKEN@api.github.com/orgs/$ORG/repos?type=all&page=$PAGE" | awk '/full_name/{print substr($2, 2, length($2)-3)}'); do
        echo "https://api.github.com/repos/${REPO}/zipball/"
        curl -s -H "Authorization: token ${TOKEN}" -L "https://api.github.com/repos/${REPO}/zipball/" > ${DIR_BCK}/${REPO}.zip
        if [ $? -ne 0 ]; then
                echo "Error on ${REPO}"
                exit 0
        fi
        DONE=$(($DONE + 1))
        echo "Repo ${DONE}/${NUMREPOS}"
   done
   PAGE=$(($PAGE + 1))
   echo "Page ${PAGE}"
   if [ ${PAGE} -gt 100 ]; then
   		exit 0
   fi
done
