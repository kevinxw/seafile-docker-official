#!/bin/bash

DOCKERFILE_DIR="."
DOCKERFILE="Dockerfile"
MULTIARCH_PLATFORMS="linux/amd64,linux/arm/v7,linux/arm64"
MULTIARCH_PLATFORMS="linux/amd64"

DOCKER_USER=""
REPO=""
TAGS=""
BUILD_ARGS=""
NO_BUILD_CACHE=""
SEAFILE_VERSION="8.0.7"

OUTPUT="--load"
while getopts u:r:t:a:f:d:o:m:v:pc flag
do
    case "${flag}" in
        t) TAGS="${TAGS} -t ${DOCKER_USER}/${REPO}:${OPTARG}";;
        u) DOCKER_USER="${OPTARG}";;
        a) BUILD_ARGS="${BUILD_ARGS} --build-arg ${OPTARG}";;
        d) DOCKERFILE_DIR="${OPTARG}";;
        f) DOCKERFILE="${OPTARG}";;
        p) OUTPUT="--push";;
        c) NO_BUILD_CACHE="yes";;
        o) OPTS="${OPTS} ${OPTARG}";;
        r) REPO="${OPTARG}";;
        v) SEAFILE_VERSION="${OPTARG}";;
        m) MULTIARCH_PLATFORMS="${OPTARG}";;
        :) exit;;
        \?) exit;;
    esac
done

if [[ -z "${REPO}" ]]; then
  echo "Repo must be specified with -r"
  exit 1
fi

if [[ -z "${DOCKER_USER}" ]]; then
  echo "Docker user must be specified with -u"
  exit 1
fi

if [[ -z "${SEAFILE_VERSION}" ]]; then
  echo "Seafile version must be specified with -v"
  exit 1
fi

SEAFILE_VERSION_ARR=($(echo $SEAFILE_VERSION | tr "." "\n"))

trap '
  trap - INT # restore default INT handler
  kill -s INT "$$"
' INT

# Enable use of docker buildx
export DOCKER_CLI_EXPERIMENTAL=enabled

# Register qemu handlers
docker run --rm --privileged tonistiigi/binfmt --install all

# create multiarch builder if needed
BUILDER=multiarch_builder
if [ "$(docker buildx ls | grep $BUILDER)" == "" ]
then
    docker buildx create --name $BUILDER
fi

# Use the builder
docker buildx use $BUILDER

# Fix docker multiarch building when host local IP changes
BUILDER_CONTAINER="$(docker ps -qf name=${BUILDER})"
if [ ! -z "${BUILDER_CONTAINER}" ]; then
  sleep 2
  if [ -z "${NO_BUILD_CACHE}" ]; then
    echo 'Restarting builder container..'
    docker restart "${BUILDER_CONTAINER}"
    sleep 10
  else
    echo 'Deleting builder container..'
    # This will clear built image cache.
    docker rm --force "${BUILDER_CONTAINER}"
   fi
fi

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR

rm -rf "scripts"
cp -rf "../../scripts_${SEAFILE_VERSION_ARR[0]}.0" ./scripts

# Build image
docker buildx build $OUTPUT --platform "$MULTIARCH_PLATFORMS" --build-arg "SEAFILE_VERSION=${SEAFILE_VERSION}" -t "${DOCKER_USER}/${REPO}:latest" -t "${DOCKER_USER}/${REPO}:${SEAFILE_VERSION}" -t "${DOCKER_USER}/${REPO}:${SEAFILE_VERSION_ARR[0]}" -t "${DOCKER_USER}/${REPO}:${SEAFILE_VERSION_ARR[0]}.${SEAFILE_VERSION_ARR[1]}" ${BUILD_ARGS} ${OPTS} -f "$DOCKERFILE" "$DOCKERFILE_DIR"

export DOCKER_CLI_EXPERIMENTAL=disabled

cd -
