#!/usr/bin/env bash

####### PARSING OPTIONS ################################################################################################

PUSH=false
FLAVOR="debian-slim"

while getopts ":u:p:U:P:g:r:v:s:hf:" opt; do
  case ${opt} in
    u ) DL_USER=$OPTARG;;
    p ) DL_PASS=$OPTARG;;
    U ) REPOSITORY_USER=$OPTARG;;
    P ) REPOSITORY_PASS=$OPTARG;;
    g ) REGISTRY=$OPTARG;;
    r ) REPOSITORY=$OPTARG;;
    v ) VERSION=$OPTARG;;
    h ) PUSH=true;;
    s ) SOURCE=$OPTARG;;
    f ) FLAVOR=$OPTARG;;
    \? ) echo "Invalid option: $OPTARG" 1>&2; exit 1;;
    : ) echo "Invalid option: $OPTARG requires an argument" 1>&2; exit 1;;
  esac
done
shift $((OPTIND -1))

if [ -z ${REGISTRY+x} ] || [ -z ${REPOSITORY+x} ] || [ -z ${VERSION+x} ] ; then
    echo "Options -v -r -g are mandatory"
    exit 1
fi

######## DOWNLOADING DIST ##############################################################################################

if [ -z ${DL_USER+x} ] || [ -z ${DL_PASS+x} ] || [ -z ${SOURCE+x} ]; then
   echo "Skipping download because download user, pass or source are not set."
else
    DIST_DEST="resources/xl-deploy-${VERSION}-server.zip"
    if [ -f $DIST_DEST ]; then
        echo "Skipping download because file already exists"
    else
        NEXUSREPO="releases"
        if [[ $VERSION = *"alpha"* ]]; then
            NEXUSREPO="alphas"
        fi

        DL_LOCATION_DIST="https://dist.xebialabs.com/customer/xl-deploy/product/${VERSION}/xl-deploy-${VERSION}-server.zip"
        DL_LOCATION_NEXUS="https://nexus.xebialabs.com/nexus/service/local/repositories/${NEXUSREPO}/content/com/xebialabs/deployit/xl-deploy/${VERSION}/xl-deploy-${VERSION}-server.zip"

        if [ "$SOURCE" = "nexus" ]; then
            DL_LOCATION=$DL_LOCATION_NEXUS
        else
            DL_LOCATION=$DL_LOCATION_DIST
        fi

        echo "File does not exist, downloading from ${DL_LOCATION}..."
        curl --fail -u "${DL_USER}:${DL_PASS}" "${DL_LOCATION}" > "${DIST_DEST}"
    fi
fi

echo "Product zip located at: ${DIST_DEST}"

echo "Building image with flavor ${FLAVOR}"
docker build --build-arg XLR_VERSION="${VERSION}" --tag "${REGISTRY}/${REPOSITORY}:${VERSION}" -f "${FLAVOR}/Dockerfile" .

####### PUSH TO REGISTRY ###############################################################################################

if  ! [ -z ${REPOSITORY_USER+x} ] && ! [ -z ${REPOSITORY_PASS+x} ] ; then
    echo "Login in to registry with user ${REPOSITORY_USER}"
    docker login -u "${REPOSITORY_USER}" -p "${REPOSITORY_PASS}"
fi

if [ $PUSH = true ]; then
    echo "Pushing image to remote"
    docker push "${REGISTRY}/${REPOSITORY}:${VERSION}"
else
    echo "Skipping push"
fi


