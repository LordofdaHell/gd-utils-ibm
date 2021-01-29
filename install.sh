#!/bin/bash
echo
echo "============== <<Satisfy the following conditions before deployment>> ============="
echo "1. Your application name"
echo "2. Your application memory size"
echo "3. The area where your application is located"
echo "4. telegram robot token"
echo "5. telegram account ID"
echo "6. The default destination google drive team disk ID"
echo "7. Obtain the SA file and package it into accounts.zip file"
echo "------------------------------------------------ "
read -s -n1 -p "Ready, please press any key to start"
echo
echo "------------------------------------------------ "

SH_PATH=$(cd "$(dirname "$0")";pwd)
cd ${SH_PATH}

create_mainfest_file(){
    echo "Configure..."
    read -p "Please enter your application name:" IBM_APP_NAME
    echo "App name: ${IBM_APP_NAME}"
    read -p "Please enter your application memory size (default 256):" IBM_MEM_SIZE
    if [-z "${IBM_MEM_SIZE}" ];then
    IBM_MEM_SIZE=256
    fi
    echo "Memory size: ${IBM_MEM_SIZE}"
    read -p "Please enter the area where your application is located (see the application URL if you don’t know it, the us-south in front of cf is):" IBM_APP_REGION
    echo "Application area: ${IBM_APP_REGION}"

    read -p "Please enter the robot token:" BOT_TOKEN
    while [[ "${#BOT_TOKEN}" != 46 ]]; do
    echo "The robot TOKEN input is incorrect, please re-enter"
    read -p """Please enter the robot token:" BOT_TOKEN
    done

    read -p "Please enter the telegram account ID of the robot:" TG_USERNAME
    echo "Your TG account ${TG_USERNAME}"

    read -p "Please enter the default destination team disk ID:" DRIVE_ID
    while [[ "${#DRIVE_ID}" != 19 && "${#DRIVE_ID}" != 33 ]]; do
    echo "Your Google team drive ID is incorrectly entered"
    read -p "Please enter the default destination ID for dump:" DRIVE_ID
    done

    cd ~ &&
    sed -i "s/cloud_fonudray_name/${IBM_APP_NAME}/g" ${SH_PATH}/IBM-gd-utils/manifest.yml &&
    sed -i "s/cloud_fonudray_mem/${IBM_MEM_SIZE}/g" ${SH_PATH}/IBM-gd-utils/manifest.yml &&
    sed -i "s/bot_token/${BOT_TOKEN}/g" ${SH_PATH}/IBM-gd-utils/gd-utils/config.js &&
    sed -i "s/your_tg_username/${TG_USERNAME}/g" ${SH_PATH}/IBM-gd-utils/gd-utils/config.js &&
    sed -i "s/DEFAULT_TARGET =''/DEFAULT_TARGET ='${DRIVE_ID}'/g" ${SH_PATH}/IBM-gd-utils/gd-utils/config.js&&
    sed -i "s/23333/8080/g" ${SH_PATH}/IBM-gd-utils/gd-utils/server.js &&
    sed -i "s@https_proxy='http://127.0.0.1:1086' nodemon@pm2-runtime start@g" ${SH_PATH}/IBM-gd-utils/gd-utils/package.json&&
    sed -i'/scripts/a\ "preinstall": "npm install pm2 -g",' ${SH_PATH}/IBM-gd-utils/gd-utils/package.json&&
    sed -i'/repository/a\ "engines": {\n "node": "12.*"\n },' ${SH_PATH}/IBM-gd-utils/gd-utils/package.json&&
    sed -i'/dependencies/a\ "pm2": "^3.2.8",' ${SH_PATH}/IBM-gd-utils/gd-utils/package.json
    echo "Configuration completed."
}

clone_repo(){
    echo "Initialize..."
    git clone https://github.com/artxia/IBM-gd-utils
    cd IBM-gd-utils
    git submodule update --init --recursive
    cd gd-utils/sa
    echo "Please click the upload function in the upper right corner of the webpage to upload the accounts.zip file packaged by sa. Note that the naming and compression format should be the same as the example"
    read -s -n1 -p "Ready, please press any key to start"
    while [! -f ${SH_PATH}/accounts.zip ]; do
    echo "... upload file error, please upload again"
    read -p "Press Enter to retry"
    done
    echo "Extracting..."
    cp -r ${SH_PATH}/accounts.zip ${SH_PATH}/IBM-gd-utils/gd-utils/sa/
    unzip -oj accounts.zip
    sleep 10s
    echo "Initialization completed."
}

install(){
    echo "Installation..."
# Remove sudu permission restrictions
    mkdir ~/.npm-global
    npm config set prefix'~/.npm-global'
    sed -i'$a\export PATH=~/.npm-global/bin:$PATH' ~/.profile
    source ~/.profile
#
    cd IBM-gd-utils/gd-utils
    npm i
    cd ..
    ibmcloud target --cf
    ibmcloud cf push
    echo "The installation is complete."
    sleep 3s
echo "Check if the deployment is successful..."
    echo ${IBM_APP_NAME}.${IBM_APP_REGION}.cf.appdomain.cloud/api/gdurl/count?fid=124pjM5LggSuwI1n40bcD5tQ13wS0M6wg
    curl ${IBM_APP_NAME}.${IBM_APP_REGION}.cf.appdomain.cloud/api/gdurl/count?fid=124pjM5LggSuwI1n40bcD5tQ13wS0M6wg
    curl -F "url=https://${IBM_APP_NAME}.${IBM_APP_REGION}.cf.appdomain.cloud/api/gdurl/tgbot"'https://api.telegram.org/bot${BOT_TOKEN}/setWebhook '
    echo
}

clone_repo
create_mainfest_file
install
exit 0
