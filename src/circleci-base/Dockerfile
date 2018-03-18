# Planet 4 CircleCI build image
# Branch: develop
# Commit: d6ba1c490e25bf6fb3577f2584e4e8184cb9c7ae
# Build:  https://circleci.com/gh/greenpeace/planet4-circleci/357
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
    curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 60 "https://releases.hashicorp.com/terraform/0.10.8/terraform_0.10.8_linux_amd64.zip" > /tmp/terraform.zip && \
    unzip /tmp/terraform.zip -d /usr/local/bin && \
    chmod 0755 /usr/local/bin/terraform && \
    curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 60 -sSOL https://github.com/gruntwork-io/terragrunt/releases/download/v0.13.17/terragrunt_linux_amd64 && \
    chmod 0755 terragrunt_linux_amd64 && \
    mv terragrunt_linux_amd64 /usr/local/bin/terragrunt && \
    curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 60 "https://beyondgrep.com/ack-2.18-single-file" > /usr/local/bin/ack && \
    chmod 0755 /usr/local/bin/ack && \
    curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 60 -L "https://github.com/docker/compose/releases/download/1.17.0/docker-compose-$(uname -s)-$(uname -m)" > /usr/local/bin/docker-compose && \
    chmod 0755 /usr/local/bin/docker-compose && \
    chmod 0755 /home/circleci/scripts/* && \
    curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 60 -sL https://deb.nodesource.com/setup_8.x | bash - && \
    export "DESIRED_VERSION=v2.7.0" && \
    curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 60 -sL https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash - && \
    apt-get install -y --no-install-recommends \
      wget \
      gettext=0.19.3-2 \
      nodejs=8.9.1-1nodesource1 \
      shellcheck=0.3.4-3 && \
    npm install -g \
      junit-merge@1.1.0 \
      tap-xunit@1.7.0 && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    rm -rf /var/lib/apt/lists/*

USER circleci

RUN curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 60 -L "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/""google-cloud-sdk-179.0.0-linux-x86_64.tar.gz" | tar xz && \
    CLOUDSDK_CORE_DISABLE_PROMPTS=1 ./google-cloud-sdk/install.sh \
        --usage-reporting false \
        --bash-completion false \
        --path-update false \
        --rc-path "/home/${CIRCLECI_USER}/.bashrc" && \
    google-cloud-sdk/bin/gcloud --quiet components update && \
    google-cloud-sdk/bin/gcloud --quiet components update kubectl
