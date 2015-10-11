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

### Directory contains dockerfile and startup for image
DOCKERBUILD_DIR="dockerbuild"

### Directory will store repository source code
REPO_DIR="${DOCKERBUILD_DIR}/www"

### File list will be removed after process
UNUSED_WWW_FILES=( \
    "${REPO_DIR}/.git" \
    "${REPO_DIR}/build.*" \
    "${REPO_DIR}/composer.*" \
    "${REPO_DIR}/README.md" \
    "${REPO_DIR}/tests" \
)

### Directory of bash script
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


################################################################################
### Extract information from commandline argument
for i in "$@"
do
case $i in
    -s=*|--searchpath=*)
    SECTION="${i#*=}"
    ;;
    -r=*|--searchpath=*)
    REPO="${i#*=}"
    ;;
    -i=*|--searchpath=*)
    DOCKER_IMAGE="${i#*=}"
    ;;
    --default)
    DEFAULT=YES
    ;;
    *)
            # unknown option
    ;;
esac
done


################################################################################
### If found section option (-s) in command,
### load INI file to find information about this section
if [ ! -z "$SECTION" ]; then

    ### Parsing INI file to get pre-define repo & image path
    ini_parser "${SCRIPT_DIR}/${SECTION_FILE}" $SECTION

    if [ -z "$repo" ]; then
        echo "[ERROR] Can not find 'repo' in section [${SECTION}]. Check your .INI file for job define."
        exit 1
    fi

    ### Init repo & dockerimage loaded from INI
    REPO=${repo}
    DOCKER_IMAGE=${image}
fi


################################################################################
### Check require REPO
if [ -z "$REPO" ]; then
        echo "[ERROR] Repository is required. Use option (-r), such as: ... -r=repourl ... or using predefined section with -s option."
        exit 1
fi


################################################################################
### Check require IMAGE
if [ -z "$DOCKER_IMAGE" ]; then
        echo "[ERROR] Docker image is required. Use option (-i), such as: ... -i=image ... or using predefined section with -s option."
        exit 1
fi


printf "*********************************************************************\n"
printf "[*] START RUNNING BUILD TASK FROM [${SCRIPT_DIR}]"

################################################################################
### Task 01: Remove current source code folder for get latest code from repo
printf "\n[TASK] Removing existed [${REPO_DIR}] folder..."
rm -rf "${SCRIPT_DIR}/${REPO_DIR}"
printf "done."


################################################################################
### Task 02: Clone code from repository
printf "\n[TASK] Cloning from [${REPO}]...\n"
git clone ${REPO} "${SCRIPT_DIR}/${REPO_DIR}"
if [ $? -eq 0 ]; then
    printf ""
else
    printf "[ERROR] repository not found or not permission. \n"
    exit 1
fi


################################################################################
### Task 03: Update composer
printf "\n[TASK] Update composer to get all Vendor\n"
cd "${SCRIPT_DIR}/${REPO_DIR}"

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
    DELETED_FILE="${SCRIPT_DIR}/${i}"
    printf "\nDeleting [${DELETED_FILE}]..."
    rm -rf ${DELETED_FILE}
    printf "OK"
done


################################################################################
### Task 05: Strip comments and space from php files
printf "\n[TASK] Remove whitespace and comments from all PHP files in [${REPO_DIR}]:\n"
PHP_FILES=$(find "${SCRIPT_DIR}/${REPO_DIR}" -type f -name '*.php')
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
cd "${SCRIPT_DIR}/${DOCKERBUILD_DIR}"
docker build -t ${DOCKER_IMAGE} .


################################################################################
### Task 07: Push new image to Docker Registry
printf "\n[TASK] Push Image [${DOCKER_IMAGE}] to Private Docker Registry:\n"
docker push ${DOCKER_IMAGE}
printf "\nPush image done."


################################################################################
### Task 08: Remove working file/directory
printf "\n[TASK] Cleaning existed [${REPO_DIR}] folder..."
rm -rf "${SCRIPT_DIR}/${REPO_DIR}"
printf "done."

################################################################################
### Task final: Show execution time in seconds
end=`date +%s`
runtime=$((end-start))
printf "\nExecution time: ${runtime}s\n"




