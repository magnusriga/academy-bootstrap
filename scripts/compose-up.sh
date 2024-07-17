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
    # "$0" returns the path to this running script, including the script name.
    # dirname strips the last path from its argunment, thus returns the directory this script is in.
    # pwd returns the current working directory.
    # Thus, the line below assumes we execute a script from a folder that is one down
    # from the root folder of the project.
    ROOTDIR="$(cd "$(dirname "$0")" && cd .. && pwd)"
    # echo "ROOTDIR: $ROOTDIR"
    # echo "${ROOTDIR}/envs/docker-$env.env"
    # Path is relative to where script is run from, so use absolute path.
    # . "${ROOTDIR}/envs/docker-$env.env"
    # docker compose --progress plain -f "${ROOTDIR}/docker/docker-compose-$env.yml" build --no-cache
    # docker compose up -d
    case "${env}" in
    dev)
      . "${ROOTDIR}/envs/.env.base"
      # docker compose --progress plain -f "${ROOTDIR}/docker/docker-compose-$env.yml" build --no-cache

      # Up does not work with terminal, because up is meant to run multiple containers.
      # Here we run it in foreground (attached) mode.
      # --build means we rebuild image, but use cache.
      # -V means rebuild volumes (all node_modules folders)
      docker compose -f "${ROOTDIR}/docker/docker-compose-$env.yml" up -V --build

      # Attached mode without building:
      # docker compose -f "${ROOTDIR}/docker/docker-compose-$env.yml" up

      # Run container in background mode, allowing us to get inside terminal with exec.
      # Remember to also turn on tty, stdin_open, init.
      # docker compose -f "${ROOTDIR}/docker/docker-compose-$env.yml" up -d --build
      # docker compose -f "${ROOTDIR}/docker/docker-compose-$env.yml" up -d
      # docker exec -it docker-nfront-website-1 bash
      ;;
    start)
      . "${ROOTDIR}/envs/.env.base"
      # docker compose --progress plain -f "${ROOTDIR}/docker/docker-compose-dev.yml" build --no-cache
      docker compose -f "${ROOTDIR}/docker/docker-compose-dev.yml" up
      ;;
    prod)
      . "${ROOTDIR}/envs/.env.base"
      # docker compose --progress plain -f "${ROOTDIR}/docker/docker-compose-$env.yml" build --no-cache
      docker compose -f "${ROOTDIR}/docker/docker-compose-combined.yml" up -d
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
# docker ps -a --no-trunc
# docker ps -a

# printf "\n\n============================================================\n\n"
# printf "docker container inspect docker-nfront-website-1 | jq -C"
# printf "\n\n============================================================\n\n"
# docker container inspect docker-nfront-website-1 | jq -C

# docker exec -it docker-nfront-website-1 bash
