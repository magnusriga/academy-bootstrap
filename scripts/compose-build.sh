#!/bin/bash

if [[ "${1}" != -* ]]; then
  echo "Set the environment with the -e flag (dev|start|prod)"
  exit 1
fi

# set -a exports all variables in this shell,
# so they are usable in subshells or scripts.
set -a

env=''
while getopts 'e:' flag; do
  case "${flag}" in
  e)
    env="${OPTARG}"
    # if [[ "${env}" != "dev" || "${env}" != "dev" || "${env}" != "dev" ]]; then
    #   echo "Unexpected option for flag -e: '${env}'. Options: dev | start | prod"
    #   exit 1
    # fi
    # SCRIPTDIR="$( cd "$( dirname "$0" )" && pwd )"
    ROOTDIR="$(cd "$(dirname "$0")" && pwd)"
    echo "ROOTDIR: $ROOTDIR"
    # echo "${ROOTDIR}/envs/docker-$env.env"
    # Path is relative to where script is run from, so use absolute path.
    # . "${ROOTDIR}/envs/docker-$env.env"
    # docker compose --progress plain -f "${ROOTDIR}/docker/docker-compose-$env.yml" build --no-cache
    # docker compose up -d
    case "${env}" in
    dev)
      . "${ROOTDIR}/envs/.env.base"
      docker compose --progress plain -f "${ROOTDIR}/docker/docker-compose-$env.yml" build --no-cache
      # docker compose -f "${ROOTDIR}/docker/docker-compose-$env.yml" up -d
      ;;
    start)
      . "${ROOTDIR}/envs/.env.base"
      docker compose --progress plain -f "${ROOTDIR}/docker/docker-compose-dev.yml" build --no-cache
      # docker compose -f "${ROOTDIR}/docker/docker-compose-dev.yml" up -d
      ;;
    prod)
      . "${ROOTDIR}/envs/.env.base"
      docker compose --progress plain -f "${ROOTDIR}/docker/docker-compose-combined.yml" build
      # docker compose -f "${ROOTDIR}/docker/docker-compose-$env.yml" up -d
      ;;
    *)
      echo "Unexpected option for flag -e: '${env}'. Options: dev | start | prod"
      exit 1
      ;;
    esac
    ;;
  *)
    exit 1
    ;;
  esac
done

# dot, synonym to "source", means to bring
# contents of subsequent file into current shell.

# Now we have all envs in current shell,
# so we execute command in this shell,
# which can now access all variables defined
# in sourced file.
docker image ls
