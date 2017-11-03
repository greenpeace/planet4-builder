# Planet 4 CircleCI build image
# Branch: master
# Commit: bec8712f07c8d6dbc6f05e2cf8893fbe2ce73b95
# Build:  https://circleci.com/gh/greenpeace/planet4-circleci/327
# ------------------------------------------------------------------------
#                     DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------

FROM circleci/php:7.0

MAINTAINER Raymond Walker <raymond.walker@greenpeace.org>

LABEL maintainer="Raymond Walker <raymond.walker@greenpeace.org>" \
      description="Planet 4 CircleCI build image: \
Base image for performing CI/CD operations in CircleCI"

USER root

ENV CIRCLECI_USER 'circleci'

WORKDIR /home/circleci

COPY ./scripts /home/circleci/scripts
COPY ./etc/apt/sources.list /etc/apt/sources.list

RUN git clone https://github.com/sstephenson/bats.git && \
    ./bats/install.sh /usr/local && \
    rm -fr /home/circleci/bats && \
    curl "https://releases.hashicorp.com/terraform/0.10.8/terraform_0.10.8_linux_amd64.zip" > /tmp/terraform.zip && \
    unzip /tmp/terraform.zip -d /usr/local/bin && \
    chmod 0755 /usr/local/bin/terraform && \
    curl -sSOL https://github.com/gruntwork-io/terragrunt/releases/download/v0.13.15/terragrunt_linux_amd64 && \
    chmod 0755 terragrunt_linux_amd64 && \
    mv terragrunt_linux_amd64 /usr/local/bin/terragrunt && \
    curl "https://beyondgrep.com/ack-2.18-single-file" > /usr/local/bin/ack && \
    chmod 0755 /usr/local/bin/ack && \
    curl -L "https://github.com/docker/compose/releases/download/1.17.0/docker-compose-$(uname -s)-$(uname -m)" > /usr/local/bin/docker-compose && \
    chmod 0755 /usr/local/bin/docker-compose && \
    chmod 0755 /home/circleci/scripts/* && \
    curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get install -y --no-install-recommends \
      gettext=0.19.3-2 \
      nodejs=8.9.0-1nodesource1 \
      shellcheck=0.3.4-3 && \
    npm install -g \
      junit-merge@1.1.0 \
      tap-xunit@1.7.0 && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    rm -rf /var/lib/apt/lists/*

USER circleci

RUN curl -L "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/""google-cloud-sdk-178.0.0-linux-x86_64.tar.gz" | tar xz && \
    CLOUDSDK_CORE_DISABLE_PROMPTS=1 ./google-cloud-sdk/install.sh \
        --usage-reporting false \
        --bash-completion false \
        --path-update false \
        --rc-path "/home/${CIRCLECI_USER}/.bashrc" && \
    google-cloud-sdk/bin/gcloud --quiet components update && \
    google-cloud-sdk/bin/gcloud --quiet components update kubectl
