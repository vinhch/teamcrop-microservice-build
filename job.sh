#!/bin/bash

################################################################################
### Function to parsing INI file
ini_parser() {
 FILE=$1
 SECTION=$2
 eval $(sed -e 's/[[:space:]]*\=[[:space:]]*/=/g' \
 -e 's/[;#].*$//' \
 -e 's/[[:space:]]*$//' \
 -e 's/^[[:space:]]*//' \
 -e "s/^\(.*\)=\([^\"']*\)$/\1=\"\2\"/" \
 < $FILE \
 | sed -n -e "/^\[$SECTION\]/I,/^\s*\[/{/^[^;].*\=.*/p;}")
}

################################################################################
### Start the timer to tracking execution time of this script
start=`date +%s`

### INI for contain all sections define
SECTION_FILE="job.ini"

### Get config repo and image from INI file
SECTION=""

### Repository will clone to process
REPO=""

### Docker image will push to update
DOCKER_IMAGE=""

### Folder contains all working directory
WORKSPACE_DIR="workspace"

### Suffix for each working directory
WORKSPACE_DIR_SUFFIX=`date +"%Y-%m-%d-%H-%M-%S-%N"`


### Directory contains dockerfile and startup for image
DOCKERBUILD_DIR="dockerbuild"




### Directory of bash script
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


################################################################################
### Extract information from commandline argument
if [ "$#" -ne 1 ]
then
  echo "Usage: ./job.sh SECTION"
  exit 1
fi

### Get section name on first command line argument
SECTION=$1



################################################################################
### load INI file to find information about this section
if [ ! -z "$SECTION" ]; then

    ### Parsing INI file to get pre-define repo & image path
    ini_parser "${SCRIPT_DIR}/${SECTION_FILE}" $SECTION

    ### Init repo & dockerimage loaded from INI
    REPO=${repo}
    DOCKER_IMAGE=${image}
fi


################################################################################
### Check require REPO
if [ -z "$REPO" ]; then
        echo "[ERROR] Repository URL can not be found in section [${SECTION}]. Please check your INI file."
        exit 1
fi


################################################################################
### Check require IMAGE
if [ -z "$DOCKER_IMAGE" ]; then
        echo "[ERROR] Docker image can not be found in section [${SECTION}]. Please check your INI file."
        exit 1
fi


printf "*********************************************************************\n"
printf "[*] START RUNNING BUILD TASK FROM [${SCRIPT_DIR}]"


############################


################################################################################
### Task 01: Everything about config is ok, init working directory

#Dynamic working directory for each build, this directory will created and remove after build
WORKING_DIR="${WORKSPACE_DIR}/${SECTION}-${WORKSPACE_DIR_SUFFIX}"
FULL_WORKING_DIR="${SCRIPT_DIR}/${WORKING_DIR}"

printf "\n[TASK] Creating temporary [${FULL_WORKING_DIR}] directory for this build..."
mkdir ${FULL_WORKING_DIR}
printf "done."

printf "\n[TASK] Copy [${DOCKERBUILD_DIR}] directory to working directory..."
cp -R "${SCRIPT_DIR}/${DOCKERBUILD_DIR}" ${FULL_WORKING_DIR}
printf "done."


### Directory will store repository source code
REPO_DIR="${FULL_WORKING_DIR}/${DOCKERBUILD_DIR}/www"

### File list will be removed after process
UNUSED_WWW_FILES=( \
    "${REPO_DIR}/.git" \
    "${REPO_DIR}/build.*" \
    "${REPO_DIR}/composer.*" \
    "${REPO_DIR}/README.md" \
    "${REPO_DIR}/tests" \
)


################################################################################
### Task 02: Clone code from repository
printf "\n[TASK] Cloning from [${REPO}]...\n"
git clone ${REPO} "${REPO_DIR}"
if [ $? -eq 0 ]; then
    printf ""
else
    printf "[ERROR] repository not found or not permission. \n"
    exit 1
fi


################################################################################
### Task 03: Update composer
printf "\n[TASK] Update composer to get all Vendor\n"
cd "${REPO_DIR}"

### Delete current Vendor
printf "\nDeleting [Vendor] directory..."
rm -rf Vendor
printf "OK"

### Update composer
printf "\nUpdating with [composer update]..."
composer update


################################################################################
### Task 04: Remove un-used files
printf "\n[TASK] Delete un-used files from [${REPO_DIR}]:"
for i in "${UNUSED_WWW_FILES[@]}"
do
    DELETED_FILE="${REPO_DIR}/${i}"
    printf "\nDeleting [${DELETED_FILE}]..."
    rm -rf ${DELETED_FILE}
    printf "OK"
done


################################################################################
### Task 05: Strip comments and space from php files
printf "\n[TASK] Remove whitespace and comments from all PHP files in [${REPO_DIR}]:\n"
PHP_FILES=$(find "${REPO_DIR}" -type f -name '*.phpdemo')
for f in $PHP_FILES
do
  printf "Processing $f file...\n"

  # we must use temp file because we can not process and output to same file
  # 1. strip and output to new file
  php -w $f > "${f}.tmp"

  # 2. Remove old file
  rm -f $f

  # 3. Rename tmp file to original filename
  mv "${f}.tmp" $f
done


################################################################################
### Task 06: Build new Docker image from
printf "\n[TASK] Build Docker Image with name [${DOCKER_IMAGE}]:\n"
cd "${FULL_WORKING_DIR}/${DOCKERBUILD_DIR}"
docker build -t ${DOCKER_IMAGE} .


################################################################################
### Task 07: Push new image to Docker Registry
printf "\n[TASK] Push Image [${DOCKER_IMAGE}] to Private Docker Registry:\n"
docker push ${DOCKER_IMAGE}
printf "\nPush image done."


################################################################################
### Task 08: Remove working file/directory
printf "\n[TASK] Cleaning working [${FULL_WORKING_DIR}] directory..."
rm -rf "${FULL_WORKING_DIR}"
printf "done."

################################################################################
### Task final: Show execution time in seconds
end=`date +%s`
runtime=$((end-start))
printf "\nExecution time: ${runtime}s\n"




