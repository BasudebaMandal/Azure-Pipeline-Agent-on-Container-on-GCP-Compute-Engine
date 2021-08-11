#!/bin/bash

set -e

FILE=$0
SCRIPT_NAME=`basename $0 | awk -F".sh" '{print $1}'`
PAT_TOKEN=$1
if [ "$#" -ne 1 ]; 
then
   echo "This Script needs to be run with one argument. Example: bash $FILE PAT_TOKEN" 
   exit 1
fi

if [ `echo $File | grep -c "/"` -eq 0 ]; then
     SCRIPT_BASE_DIR=`pwd`
else
     SCRIPT_BASE_DIR="${File%/*}"
fi

cd ${SCRIPT_BASE_DIR}
. ${SCRIPT_BASE_DIR}/config.properties

### Following If-else logic ensures that key of a service-account is valid and not re-created if already available. 

if [ -s "$GCP_CRED_KEY_FILE_PATH_ON_HOST" ]; then
    SACCOUNT_IN_KEY=`cat ${GCP_CRED_KEY_FILE_PATH_ON_HOST} | jq -r .client_email`
    if [ "$SERVICE_ACCOUNT" = "$SACCOUNT_IN_KEY" ]; then
      echo "Using the existing key available on Host."
    else
      echo "You seem to have either configured a different service account than the last one or the key is tamppered. Changing the service-account is not recommended if you had registered this docker agent earlier."
	  echo "Tampered keys would not work with agent registration, hence the existing key on the host can be deleted so that a fresh key would be generated"
	  echo "If you are installing/registering  this docker agent for the first time, Then it looks like a wrong key has been copied at $GCP_CRED_KEY_FILE_PATH_ON_HOST."
	  echo "Please delete the key $GCP_CRED_KEY_FILE_PATH_ON_HOST and re-run the script. It would create a fresh key for the service account being used here. "
      exit 1
    fi
else 
    gcloud iam service-accounts keys create $GCP_CRED_KEY_FILE_PATH_ON_HOST --iam-account=$SERVICE_ACCOUNT
fi
cp -rp $GCP_CRED_KEY_FILE_PATH_ON_HOST $SCRIPT_BASE_DIR

### Below piece of code ensures to find out the latest version of azure-pipeline agent and changes the Dockerfile to create agents using latest version.
AZP_AGENT_VERSION=`curl -H "Accept: application/vnd.github.v3+json"  https://api.github.com/repos/microsoft/azure-pipelines-agent/releases/latest | jq ".tag_name" | sed -e 's/^"//' -e 's/"$//' -e 's/^v//'`
sed -i -e "s/AZP_AGENT_VERSION/${AZP_AGENT_VERSION}/g" Dockerfile
sed -i -e "s/SERVICE_ACCOUNT/${SERVICE_ACCOUNT}/g" Dockerfile
sed -i -e "s/GCP_PROJECT/${GCP_PROJECT}/g" Dockerfile

###Following code ansures that the host machine does not have same docker image already. If the image is alreay built, it goes for verifying if the container is running. And if not - it creates the container out of it .

if [ -z "$(docker images -q ${IMAGE_NAME})" ]; then
    docker build -t ${IMAGE_NAME} .
fi

for (( i=$STARTING_AGENT_NUMBER; i<$STARTING_AGENT_NUMBER+$NUMBER_OF_AGENTS; i++ ))
do
    AGENT_NAME="${AGENT_NAME_PREFIX}$(printf "%02d" $i)"
    if docker inspect ${AGENT_NAME} > /dev/null 2>&1; then
        echo "$AGENT_NAME is already running..."
    else
        echo "Starting agent: $AGENT_NAME..."
        SHARED_DIR="$(pwd)/${AGENT_NAME}_SHARED"
        if [ ! -d ${SHARED_DIR} ]; then
            mkdir -p ${SHARED_DIR}
        fi
        chmod a+w ${SHARED_DIR}
        docker run --name=${AGENT_NAME} -d -h ${AGENT_NAME} \
            -v ${SHARED_DIR}:/host_shared \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -e GOOGLE_APPLICATION_CREDENTIALS=${GCP_CRED_KEY_FILE_PATH_ON_CONTAINER} \
            -e AZP_URL=${AZP_URL} \
            -e AZP_TOKEN=${THE_PAT} \
            -e AZP_POOL=${AZP_POOL} \
            -e HOST_AGENT_STAGING_AREA=${SHARED_DIR} \
            ${IMAGE_NAME}
    fi
done

rm -rf ${GCP_CRED_KEY_FILE_ON_HOST}
