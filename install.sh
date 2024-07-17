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

# Add the decoded version of the private key to the ssh-agent.
# since we added an encoded version of it to GitHub actions.
ssh-add <(echo "$SSH_PRIVATE_KEY" | base64 --decode)

if [ ! -f "envs/.env.${ENV_FILE_NAME}.local" ]; then
  # Download the environment variables file.
  custom_echo "Error: the env folder did not have the file specified with ENV_FILE_NAME: ${ENV_FILE_NAME}."
  exit 1
fi
rm -rf envs
git clone git@github.com:magnusriga/envs.git
cp -f envs/.env."${ENV_FILE_NAME}".local .env.local
chmod 744 .env.local

# Download the environment variables file.
# nfront_download -o /dev/null "$(nvm_source "script-nvm-exec")"
# touch ./.env.local
# chmod 744 ./.env.local
# curl -O "https://raw.githubusercontent.com/magnusriga/academy-envs/main/${ENV_FILE_NAME}"

# Source all environment variables from the downloaded file into the current shell.
# set -a # automatically export all variables
# source .env.local
# set +a


} # this ensures the entire script is downloaded #
