# Planet 4 CircleCI build image
# Branch: develop
# Commit: ba552d4eb235a608b527c52b0c455d38162d5cc9
# Build:  https://circleci.com/gh/greenpeace/planet4-circleci/296
# ------------------------------------------------------------------------
#                     DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------

FROM circleci/php:7.0

MAINTAINER Raymond Walker <raymond.walker@greenpeace.org>

USER root

ENV CIRCLECI_USER 'circleci'

WORKDIR /home/circleci

COPY ./scripts /home/circleci/scripts
COPY ./etc/apt/sources.list /etc/apt/sources.list

RUN git clone https://github.com/sstephenson/bats.git && \
    ./bats/install.sh /usr/local && \
    rm -fr /home/circleci/bats && \
    curl "https://releases.hashicorp.com/terraform/0.10.7/terraform_0.10.7_linux_amd64.zip" > /tmp/terraform.zip && \
    unzip /tmp/terraform.zip -d /usr/local/bin && \
    chmod 0755 /usr/local/bin/terraform && \
    curl "https://beyondgrep.com/ack-2.18-single-file" > /usr/local/bin/ack && \
    chmod 0755 /usr/local/bin/ack && \
    curl -L "https://github.com/docker/compose/releases/download/1.16.1/docker-compose-$(uname -s)-$(uname -m)" > /usr/local/bin/docker-compose && \
    chmod 0755 /usr/local/bin/docker-compose && \
    chmod 0755 /home/circleci/scripts/* && \
    apt-get update && apt-get install -y --no-install-recommends \
      gettext \
      shellcheck && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    rm -rf /var/lib/apt/lists/*

USER circleci

RUN curl -L "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/""google-cloud-sdk-176.0.0-linux-x86_64.tar.gz" | tar xz && \
    CLOUDSDK_CORE_DISABLE_PROMPTS=1 ./google-cloud-sdk/install.sh \
        --usage-reporting false \
        --bash-completion false \
        --path-update false \
        --rc-path "/home/${CIRCLECI_USER}/.bashrc" && \
    google-cloud-sdk/bin/gcloud --quiet components update && \
    google-cloud-sdk/bin/gcloud --quiet components update kubectl
