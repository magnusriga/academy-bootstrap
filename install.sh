#!/usr/bin/env bash

{ # this ensures the entire script is downloaded #

nfront_has() {
  type "$1" > /dev/null 2>&1
}

custom_echo() {
  command printf %s\\n "$*" 2>/dev/null
}

if [ -z "${ENV_FILE_NAME}" ]; then
  # shellcheck disable=SC2016
  custom_echo >&2 'Error: ENV_FILE_NAME needs to be set.'
  exit 1
fi

if [ -z "${SSH_PRIVATE_KEY}" ]; then
  # shellcheck disable=SC2016
  custom_echo >&2 'Error: SSH_PRIVATE_KEY needs to be set.'
  exit 1
fi

nfront_grep() {
  GREP_OPTIONS='' command grep "$@"
}

nfront_install_dir() {
  if [ -n "$INSTALL_DIR" ]; then
    printf %s "${INSTALL_DIR}"
  else
    printf %s "."
  fi
}

nfront_latest_version() {
  custom_echo "v1.0.0"
}

env_source() {
  NFRONT_GITHUB_REPO="${NFRONT_INSTALL_GITHUB_REPO:-magnusriga}"
  local ENV_SOURCE_URL
  ENV_SOURCE_URL="https://raw.githubusercontent.com/${NFRONT_GITHUB_REPO}/academy-envs/main/${ENV_FILE_NAME}"
  custom_echo "$ENV_SOURCE_URL"
}

nfront_source() {
  NFRONT_GITHUB_REPO="${NFRONT_INSTALL_GITHUB_REPO:-magnusriga}"
  local NFRONT_SOURCE_URL
  NFRONT_SOURCE_URL="https://raw.githubusercontent.com/${NFRONT_GITHUB_REPO}/nfront/main"
  custom_echo "$NFRONT_SOURCE_URL"
}

nfront_download() {
  if nfront_has "curl"; then
    curl --fail --compressed -q "$@"
  elif nvm_has "wget"; then
    # Emulate curl with wget
    ARGS=$(custom_echo "$@" | command sed -e 's/--progress-bar /--progress=bar /' \
                            -e 's/--compressed //' \
                            -e 's/--fail //' \
                            -e 's/-L //' \
                            -e 's/-I /--server-response /' \
                            -e 's/-s /-q /' \
                            -e 's/-sS /-nv /' \
                            -e 's/-o /-O /' \
                            -e 's/-C - /-c /')
    # shellcheck disable=SC2086
    eval wget $ARGS
  fi
}

sudo apt install ssh-askpass
ssh-keyscan -t rsa github.com >>~/.ssh/known_hosts

# Run ssh-agent in the background (-s).
eval $(ssh-agent -s)
echo "Agent now running, adding private key to ssh-agent via ssh-add..."


# Source all environment variables from the downloaded file into the current shell.
set -a # automatically export all variables

# Name of the private repository.
ACADEMY_BOOTSTRAP_PRIVATE="academy-bootstrap-private"

# Name of the temporary directory.
# Do not change these, the script files rely on these names.
export ENV_DIR="envs" # Exported because it is used in the compose file and the Dockerfile.
DOCKER_DIR="docker"
SCRIPTS_DIR="scripts"
rm -rf ${ACADEMY_BOOTSTRAP_PRIVATE}
rm -rf ${ENV_DIR}
rm -rf ${DOCKER_DIR}
rm -rf ${SCRIPTS_DIR}
mkdir ${ENV_DIR}
mkdir ${DOCKER_DIR}
mkdir ${SCRIPTS_DIR}

# The environment SSH_PRIVATE_KEY_* variables contains the encoded version
# of the private ssh keys.
# Therefore, decode them as we add them to ssh-agent.
# ssh-agent uses them to check against the public keys on GitHub.
# Add one at a time, before each git clone.
ssh-add <(echo "$SSH_PRIVATE_KEY_BOOTSTRAP" | base64 --decode)

# Download the environment variables file.
git clone git@github.com:magnusriga/academy-bootstrap-private.git
if ! [ -f ${ACADEMY_BOOTSTRAP_PRIVATE}/${ENV_DIR}/.env.${ENV_FILE_NAME}.local ]; then
  # Download the environment variables file.
  custom_echo "Error: the env folder did not have the file specified with ENV_FILE_NAME: ${ENV_FILE_NAME}."
  exit 1
fi
cp -f ${ACADEMY_BOOTSTRAP_PRIVATE}/${ENV_DIR}/.env."${ENV_FILE_NAME}".local ${ENV_DIR}/.env.local
cp -f ${ACADEMY_BOOTSTRAP_PRIVATE}/${ENV_DIR}/.env.base ${ENV_DIR}/.env.base
cp -fa ${ACADEMY_BOOTSTRAP_PRIVATE}/${DOCKER_DIR}/. ${DOCKER_DIR}
cp -fa ${ACADEMY_BOOTSTRAP_PRIVATE}/${SCRIPTS_DIR}/. ${SCRIPTS_DIR}
rm -rf ${ACADEMY_BOOTSTRAP_PRIVATE}
chmod -R 744 ${ENV_DIR}
chmod -R 744 ${DOCKER_DIR}
chmod -R 744 ${SCRIPTS_DIR}

source ${ENV_DIR}/.env.local

eval $(ssh-agent -s)
echo "Agent now running..."
ssh-add <(echo "$SSH_PRIVATE_KEY_NFRONT" | base64 --decode)

# Run the docker compose build script.
custom_echo "Running docker compose build script..."
# source ./${SCRIPTS_DIR}/compose-build.sh -e prod

# Not sure why, but trying to repeat it here.
export ENV_DIR="envs" # Exported because it is used in the compose file and the Dockerfile.

# Run the docker compose up script.
custom_echo "Running docker compose up script..."
source ./${SCRIPTS_DIR}/compose-up.sh -e prod

set +a

# Remove the environment variables and other temp files,
# now that container is built.
custom_echo "Cleaning up temp folders..."
rm -rf ${ACADEMY_BOOTSTRAP_PRIVATE}
rm -rf ${ENV_DIR}
rm -rf ${DOCKER_DIR}
rm -rf ${SCRIPTS_DIR}

# Clean up docker cache.
custom_echo "Cleaning up docker cache..."
docker system prune -f
docker system prune -f

} # this ensures the entire script is downloaded #
