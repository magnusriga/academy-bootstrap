# ==========================================================================
# ENVIRONMENT VARIABLES
# ==========================================================================
# To make environment variables available in this Dockerfile,
# we must meet one requirement:
#  * The environment variables must be set with ENV in this Dockerfile,
#    in the build stage that it is used in.
#    ENV can be hardcoded below, or set via ARG
#    ARG comes from args in the compose file.
# To make environment variables available to Node.js applications,
# run by the below Dockerfile, e.g. next build, the following conditions must be met:
#  * The environment variables must be added to the correct build stage of the Doockerfile (see above).
#  * THe environment variables must be added to turbo.json of the Next.js app.
# ==========================================================================

FROM node:22-alpine AS alpine

# Add useful packages to initial image.
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk update
RUN apk add --no-cache \
  libc6-compat \
  curl \
  sudo \
  wget \
  git \
  openssh-client
# nano \
# bash \
# file \
# wget \
# python3 \
# make \
# jq \
# vim \
# xclip  \
# g++

FROM alpine AS base

# SHELL ["/bin/bash", "-l", "-euxo", "pipefail", "-c"]

# Install pnpm so it is available to all build stages with this stage as ancestor.
# https://pnpm.io/docker
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
# https://nodejs.org/api/corepack.html
# "corepack enable" sets up symlinks to pnpm in environment next to node binary.
RUN corepack enable pnpm

FROM base AS pruner

# ==========================================================================
# ENVIRONMENT VARIABLES
# ==========================================================================
# Set environment variables we want available in all build stages,
# and in the final image and thus any running containers.

ARG NEXT_PUBLIC_POSTHOG_KEY
ENV NEXT_PUBLIC_POSTHOG_KEY=${NEXT_PUBLIC_POSTHOG_KEY}

ARG NEXT_PUBLIC_POSTHOG_HOST
ENV NEXT_PUBLIC_POSTHOG_HOST=${NEXT_PUBLIC_POSTHOG_HOST}

ARG PIPEDRIVE_API_TOKEN
ENV PIPEDRIVE_API_TOKEN=${PIPEDRIVE_API_TOKEN}

ARG CLERK_SECRET_KEY
ENV CLERK_SECRET_KEY=${CLERK_SECRET_KEY}

ARG NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
ENV NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=${NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY}

ARG CUSTOM_CACHE_HANDLER
ENV CUSTOM_CACHE_HANDLER=${CUSTOM_CACHE_HANDLER}

ARG CONTENTFUL_SPACE_ID
ENV CONTENTFUL_SPACE_ID=${CONTENTFUL_SPACE_ID}

ARG CONTENTFUL_PREVIEW_ACCESS_TOKEN
ENV CONTENTFUL_PREVIEW_ACCESS_TOKEN=${CONTENTFUL_PREVIEW_ACCESS_TOKEN}

ARG CONTENTFUL_SPACE_ID_COMPANY
ENV CONTENTFUL_SPACE_ID_COMPANY=${CONTENTFUL_SPACE_ID_COMPANY}

ARG CONTENTFUL_PREVIEW_ACCESS_TOKEN_COMPANY
ENV CONTENTFUL_PREVIEW_ACCESS_TOKEN_COMPANY=${CONTENTFUL_PREVIEW_ACCESS_TOKEN_COMPANY}

ARG CONTENTFUL_ACCESS_TOKEN
ENV CONTENTFUL_ACCESS_TOKEN=${CONTENTFUL_ACCESS_TOKEN}

ARG CONTENTFUL_ACCESS_TOKEN_COMPANY
ENV CONTENTFUL_ACCESS_TOKEN_COMPANY=${CONTENTFUL_ACCESS_TOKEN_COMPANY}

ARG CONTENTFUL_PREVIEW_SECRET
ENV CONTENTFUL_PREVIEW_SECRET=${CONTENTFUL_PREVIEW_SECRET}

ARG CONTENTFUL_PREVIEW_SECRET_COMPANY
ENV CONTENTFUL_PREVIEW_SECRET_COMPANY=${CONTENTFUL_PREVIEW_SECRET_COMPANY}

ARG MY_SECRET_TOKEN
ENV MY_SECRET_TOKEN=${MY_SECRET_TOKEN}

# ==========================================================================

ARG APP
ENV APP=${APP}

# Set working directory
WORKDIR /app

# Get right app from build args (see docker-compose).
# Enables us to use one shared Dockerfile.
ARG APP

# Replace <your-major-version> with the major version installed in your repository. For example:
# RUN yarn global add turbo@^2
RUN pnpm add -g turbo

# Copy the entire workspace, relative to the context folder ("nfront") into the image.
# This is temporary, as later stages only copy from pruned folders (see below).
# COPY . .

# ====================================
# ALLOWING GIT CLONE VIA SSH.
#
# Instead of copying from a local working directory, we can also use a git repository.
# This is useful for CI/CD pipelines, where the source code is not available locally.
#
# Apporach 1:
# Create a /root/.ssh/id_rsa file in the image,
# and store the private SSH key in in.
# REMEMBER: Pass in the secret key as a build arg.
# Then add github.com to known_hosts.
# This is needed to make the git clone work, further down.
# ARG PRIVATE_SSH_KEY=""
# RUN mkdir /root/.ssh && chmod -R 700 /root/.ssh
# RUN echo "${SSH_PRIVATE_KEY}" >> /root/.ssh/id_rsa
# RUN echo ${SSH_PRIVATE_KEY}
# RUN chmod 0400 /root/.ssh/id_rsa && echo "StrictHostKeyChecking no" > /root/.ssh/config
# RUN cat /root/.ssh/id_rsa
# RUN ssh-keyscan github.com >> /root/.ssh/known_hosts

# Approach 2:
# It is not reccommended to add the secret key to the image,
# even if it is a multistage build where the secret is not part of the final image.
# Instead, use ssh in the compose file, to connect the docker container to the socket
# of the ssh-agent on the host machine.
# That way, git clone with ssh inside the docker container will simply use the ssh-agent
# on the host machine, which should already have the secret key loaded.
# Requirements:
# 1) Ensure the host machine has the secret key added to its ssh-agent.
#    Done via an env, in CI/CL: ssh-add <(echo "$PRIVATE_SSH_KEY").
#    Not done via a file in CI/CL, because we do not want to store the secret key on the server.
# 2) Include the ssh option in the compose file.
# 3) Run the bootstrap script (see: ./scripts/bootstrap-docker-prod.sh).
# 4) Clone via the ADD command in the Dockerfile.
#
# Notes:
# I do not think passpharases are supported, because it requires user to input
# the passphrase the first thime ssh-add runs, which is not possible in a non-interactive build.
#
# Guides:
# Docker compose ssh: https://docs.docker.com/compose/compose-file/build/#ssh
# With RUN flags instead (prefer compose file): https://docs.docker.com/reference/dockerfile/#run---mounttypessh
# Adding private Git repositories: https://docs.docker.com/reference/dockerfile/#adding-private-git-repositories
#
ADD git@github.com:magnusriga/nfront.git .
#
RUN ls -l
# ====================================

# Prune removes all files not needed to build target workspace.
# Examples of excluded files: tsconfig, .eslintrc.js, prettierrc.js, etc.
RUN turbo prune @nfront/${APP} --docker

# Add lockfile and package.json's of isolated subworkspace
FROM base AS installer

# Set working directory
WORKDIR /app

# Get right app from build args (see docker-compose).
# Enables us to use one shared Dockerfile.
ARG APP

COPY .gitignore .gitignore
COPY .syncpackrc.js .syncpackrc.js

# First, copy and install the dependencies.
# Do this before copying source files, as the latter changes more frequently
# and thus invalidates cache for all subsequent commands.
# json folder only contains all package.json files from all packages in workspace.
COPY --from=pruner /app/out/json/ .
COPY --from=pruner /app/out/pnpm-lock.yaml ./pnpm-lock.yaml
# Not sure if needed:
# COPY --from=pruner /app/out/pnpm-workspace.yaml ./pnpm-workspace.yaml

# It is impossible to create reflinks or hardlinks between a Docker container and the host filesystem during build time.
# The next best thing you can do is using BuildKit cache mount to share cache between builds.
# Which will use cache from Docker Engine storage on host machine.
# Using the explicit cache with the --mount flag saves and retreives the pnpm store content in host storage, inside Docker Engine.
# When this layer needs to be rebuilt, or in similar calls below, Docker will use the pnpm store from that cache storage on host machine.
RUN pnpm -v
RUN --mount=type=cache,id=pnpm,target={PNPM_HOME}/store pnpm install --frozen-lockfile

# Add lockfile and package.json's of isolated subworkspace
FROM installer AS builder

# Set working directory
WORKDIR /app

# Get right app from build args (see docker-compose).
# Enables us to use one shared Dockerfile.
# Necessary to set ENV, otherwise CMD with these variables will not work.
ARG APP
ENV APP=${APP}
ARG START_COMMAND=dev
ENV START_COMMAND=${START_COMMAND}

# Then, copy source files
COPY --from=pruner /app/out/full/ .
COPY turbo.json turbo.json

# Next.js collects completely anonymous telemetry data about general usage.
# Learn more here: https://nextjs.org/telemetry
# Uncomment the following line in case you want to disable telemetry during the build.
ENV NEXT_TELEMETRY_DISABLED 1

# Copy over the .env.local file.
COPY .env.local .

# Build the project and its dependencies
RUN pnpm turbo run build --filter=@nfront/${APP}...

FROM base AS runner

# Set working directory
WORKDIR /app

# Get right app from build args (see docker-compose).
# Enables us to use one shared Dockerfile.
ARG APP

# Uncomment and use build args to enable remote caching.
# No need to set env_file in docker-compose.yml,
# Docker automatically uses the .env file at root.
ARG TURBO_TEAM
ENV TURBO_TEAM=${TURBO_TEAM}

ARG TURBO_TOKEN
ENV TURBO_TOKEN=${TURBO_TOKEN}

# Next.js collects completely anonymous telemetry data about general usage.
# Learn more here: https://nextjs.org/telemetry
# Uncomment the following line in case you want to disable telemetry during the build.
ENV NEXT_TELEMETRY_DISABLED 1

# Don't run production as root
RUN addgroup --system --gid 1001 nextjs
RUN adduser --system --uid 1001 nfront
USER nfront

COPY --from=builder /app/apps/${APP}/next.config.mjs .
COPY --from=builder /app/apps/${APP}/package.json .

# Copy built files into container
# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=builder --chown=nfront:nextjs /app/apps/${APP}/.next/standalone ./
COPY --from=builder --chown=nfront:nextjs /app/apps/${APP}/.next/static ./apps/${APP}/.next/static
COPY --from=builder --chown=nfront:nextjs /app/apps/${APP}/public ./apps/${APP}/public
COPY --from=builder --chown=nfront:nextjs /app/apps/${APP}/healthcheck.js ./apps/${APP}/


# ${PORT} and ${HOSTNAME} are used by server.js.
# In server.js, ${PORT} defaults to 3000,
# which is overwritten by below default,
# which in turn is overwritten by build args / docker-compose.yml.
ARG PORT=3000
ENV PORT=${PORT}

# server.js sets NODE_ENV=production.
# Value below affects healthcheck, which uses
# HOSTNAME || "0.0.0.0" if development, otherwise VERCEL_URL.
# ENV NODE_ENV=production

# Below is just for documentation, it has no effect.
# Actual ports are set in docker-compose.yml.
EXPOSE ${PORT}

# Below CMD works
CMD node apps/${APP}/server.js

# ==============================================================
# NOTES
# ==============================================================
#
# There are three ways to run app:
# ----------------------------------
# 1) node apps/${APP}/server.js
#   - Production server (sets NODE_ENV=production)
#   - Uses standalone build
#   - hostname: Container $HOSTNAME if set (which it seems to be in containers), otherwise 0.0.0.0
# 2) next start
#   - Development server (to test build output, no hot-reload)
#   - Does not use standalone, so needs all source files (not just those from standalone)
#   - hostname: localhost
# 3) next dev
#   - Development server (with hot-reload)
#   - Does not use standalone, so needs all source files (not just those from standalone)
#   - hostname: localhost
#
# Development in container:
# ----------------------------------
#   - If running with next start or next dev,
#     we need to stop image at builder stage by setting target: builder in compose file,
#     and inject command, also in compose file, with command: next dev.
#
# Volumes:
# ----------------------------------
#   - volumes define mount host paths or named volumes that are accessible by one or more service containers.
#   - You can use volumes to define multiple types of mounts; volume, bind, tmpfs, or npipe.
#   - Bind mounts are file(s)/folder(s) on host bound to container folders, so container is held up to date when host file(s)/folder(s) changes.
#   - Volumes are folders stored in Docker Engine, so they persist between re-builds of image.
#   - Bind mounts also persist through rebuilds, because are just pointers to host file system (but appear as container folders).
#   - If mount is host path and is only used by single service, it can be declared as part of service definition.
#   - To reuse volume across multiple services, named volume must be declared in the top-level volumes key.
#   - Short syntax: VOLUME:CONTAINER_PATH, where VOLUME is name or host path (if starting with /).
#   - You can use volumes to define multiple types of mounts; volume, bind, tmpfs, or npipe.
#   - Bind
#     - Bind mounts are specific files/folders on host machine are mapped into container.
#     - So, when mapped host files/folders change, same is seen inside container.
#     - When host files/folder change, same is reflected in container.
#     - Source (host) and target (container) folder is set when bind mount is set up
#     - Bind mounts persist between image builds, because they are just pointers to specific host files/folders.
#   - Volume
#     - Folder appearing inside container, which is just pointer to folder in Docker Engine
#     - Thus, since folder is saved in Docker Engine, it persists between rebuilds of image.
#   - Defaults
#     - When using short syntax, Docker is smart about what type volume filed will create.
#     - /host/path/file:container/path/file <-- Creates bind (mount), can also be relative path
#     - name:container/path/file            <-- Named volume
#     - container/path/file                 <-- Anonymous volume

# Untested
# ARG START_COMMAND=dev
# CMD pnpm --filter ${APP} ${START_COMMAND}

# ENTRYPOINT [ "node", 'apps/${APP}/server.js']
# ENTRYPOINT [ "bin/bash", '-c' ]
# CMD ["pnpm start"]
