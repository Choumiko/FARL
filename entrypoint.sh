#!/bin/bash

# Parse the tag we're on, do nothing if there isn't one
TAG=$(git tag --points-at)
if [[ -z "${TAG}" ]]; then
    echo "Not a tag push, skipping"
    exit 78
fi

# Validate the version string we're building
if ! echo "${TAG}" | grep -P --quiet '^\d+\.\d+\.\d+$'; then
    echo "Bad version, needs to be %u.%u.%u"
    exit 1
fi

INFO_VERSION=$(jq -r '.version' info.json)
# Make sure the info.json is parseable and has the expected version number
if ! [[ "${INFO_VERSION}" == "${TAG}" ]]; then
    echo "Tag version ${TAG} doesn't match info.json version ${INFO_VERSION} (or info.json is invalid), failed"
    exit 1
fi
echo ${INFO_VERSION}
# Pull the mod name from info.json
NAME=$(jq -r '.name' info.json)
PACKAGE_FILE="${NAME}_${INFO_VERSION}.zip"
DIST_DIR="build"
FILE_PATH=$DIST_DIR/$PACKAGE_FILE
FILESIZE=$(stat -c "%s" "${FILE_PATH}")
echo ${FILE_PATH} ${FILESIZE}

# Get a CSRF token by loading the login form
CSRF=$(curl -b cookiejar.txt -c cookiejar.txt -s https://mods.factorio.com/login | grep csrf_token | sed -r -e 's/.*value="(.*)".*/\1/')

# Authenticate with the credential secrets and the CSRF token, getting a session cookie for the authorized user
curl -b cookiejar.txt -c cookiejar.txt -s -F "csrf_token=${CSRF}" -F "username=${FACTORIO_USER}" -F "password=${FACTORIO_PASSWORD}" -o /dev/null https://mods.factorio.com/login

# Query the mod info, verify the version number we're trying to push doesn't already exist
curl -b cookiejar.txt -c cookiejar.txt -s "https://mods.factorio.com/api/mods/${NAME}/full" | jq -e ".releases[] | select(.version == \"${TAG}\")"
# store the return code before running anything else
STATUS_CODE=$?

if [[ $STATUS_CODE -ne 4 ]]; then
    echo "Release already exists, skipping"
    exit 78
fi
echo "Release doesn't exist for ${TAG}, uploading"

# Load the upload form, getting an upload token
UPLOAD_TOKEN=$(curl -b cookiejar.txt -c cookiejar.txt -s "https://mods.factorio.com/mod/${NAME}/downloads/edit" | grep token | sed -r -e "s/.*token: '(.*)'.*/\1/")
if [[ -z "${UPLOAD_TOKEN}" ]]; then
    echo "Couldn't get an upload token, failed"
    exit 1
fi

# Upload the file, getting back a response with details to send in the final form submission to complete the upload
UPLOAD_RESULT=$(curl -b cookiejar.txt -c cookiejar.txt -s -F "file=@${FILE_PATH};type=application/x-zip-compressed" "https://direct.mods-data.factorio.com/upload/mod/${UPLOAD_TOKEN}")

# Parse 'em and stat the file for the form fields
CHANGELOG=$(echo "${UPLOAD_RESULT}" | jq -r '@uri "\(.changelog)"')
INFO=$(echo "${UPLOAD_RESULT}" | jq -r '@uri "\(.info)"')
FILENAME=$(echo "${UPLOAD_RESULT}" | jq -r '.filename')
THUMBNAIL=$(echo "${UPLOAD_RESULT}" | jq -r '.thumbnail // empty')

if [[ "${FILENAME}" == "null" ]] || [[ -z "${FILENAME}" ]]; then
    echo "Upload failed"
    exit 1
fi
echo "Uploaded ${NAME}_${TAG}.zip to ${FILENAME}, submitting as new version"

# Post the form, completing the release
curl -b cookiejar.txt -c cookiejar.txt -s -X POST -d "file=&info_json=${INFO}&changelog=${CHANGELOG}&filename=${FILENAME}&file_size=${FILESIZE}&thumbnail=${THUMBNAIL}" -H "Content-Type: application/x-www-form-urlencoded" -o /dev/null "https://mods.factorio.com/mod/${NAME}/downloads/edit"

echo "Completed"