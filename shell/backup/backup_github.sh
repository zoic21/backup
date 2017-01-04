#!/bin/sh

LOGIN=jeedom
TOKEN=16bad1c194f9786a00ea2b6506295287996b3f8f
ORG=jeedom
DONE=0
PAGE=0

NUMREPOS=$(curl -s "https://$LOGIN:$TOKEN@api.github.com/orgs/$ORG" | awk '
   /public_repos/{t+=$2}
   /total_private_repos/{t+=$2}
   END{print t}')

echo "Num repos : ${NUMREPOS}"

while [ ${DONE} -lt ${NUMREPOS} ]; do
   for REPO in $(curl -s "https://$LOGIN:$TOKEN@api.github.com/orgs/$ORG/repos?type=all&page=$PAGE" | awk '/full_name/{print substr($2, 2, length($2)-3)}'); do
        cd ${HOME}
        echo "https://api.github.com/repos/${REPO}/zipball/"
        curl -s -H "Authorization: token ${TOKEN}" -L "https://api.github.com/repos/${REPO}/zipball/" > ${REPO}.zip
        if [ $? -ne 0 ]; then
                echo "Error on ${REPO}"
        fi
        DONE=$(($DONE + 1))
        echo "Repo ${DONE}/${NUMREPOS}"
   done
   PAGE=$(($PAGE + 1))
   echo "Page ${PAGE}"
done
