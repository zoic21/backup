#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
PWD=$(pwd)
cd ${DIR}
git reset --hard HEAD
git pull
find ${DIR} -iname "*.sh" -type f -exec dos2unix {} \;
find ${DIR} -iname "*.sh" -type f -exec chmod +x {} \;
cd ${PWD}
