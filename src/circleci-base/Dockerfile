# Planet 4 CircleCI build image
# Branch: develop
# Commit: b99b21c61535353b7ce3250eadfc90370a212ce0
# Build:  https://circleci.com/gh/greenpeace/planet4-circleci/639
# ------------------------------------------------------------------------
#                     DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------

FROM circleci/php:7.0-node-browsers

LABEL maintainer="${MAINTAINER}" \
      description="Planet 4 CircleCI build image: \
Base image for performing CI/CD operations in CircleCI"

USER root

ENV CIRCLECI_USER="circleci" \
    PATH="/home/circleci/scripts:/home/circleci/google-cloud-sdk/bin:${PATH}"

WORKDIR /home/circleci

COPY ./scripts /home/circleci/scripts
COPY ./etc/ /etc

RUN git clone https://github.com/sstephenson/bats.git && \
    ./bats/install.sh /usr/local && \
    rm -fr /home/circleci/bats && \
    curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 60 "https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip" > /tmp/terraform.zip && \
    unzip /tmp/terraform.zip -d /usr/local/bin && \
    chmod 0755 /usr/local/bin/terraform && \
    curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 60 -sSOL https://github.com/gruntwork-io/terragrunt/releases/download/v0.14.11/terragrunt_linux_amd64 && \
    chmod 0755 terragrunt_linux_amd64 && \
    mv terragrunt_linux_amd64 /usr/local/bin/terragrunt && \
    curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 60 "https://beyondgrep.com/ack-2.24-single-file" > /usr/local/bin/ack && \
    chmod 0755 /usr/local/bin/ack && \
    curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 60 -L "https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m)" > /usr/local/bin/docker-compose && \
    chmod 0755 /usr/local/bin/docker-compose && \
    chmod 0755 /home/circleci/scripts/* && \
    curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 60 -sL https://deb.nodesource.com/setup_8.x | bash - && \
    export "DESIRED_VERSION=v2.9.1" && \
    curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 60 -sL https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash - && \
    wget https://github.com/jwilder/dockerize/releases/download/v0.6.1/dockerize-linux-amd64-v0.6.1.tar.gz && \
    tar -C /usr/local/bin -xzvf dockerize-linux-amd64-v0.6.1.tar.gz && \
    chmod 755 /usr/local/bin/dockerize && \
    rm dockerize-linux-amd64-v0.6.1.tar.gz && \
    apt-get install -y --no-install-recommends \
      gettext \
      jq \
      shellcheck \
      vim \
      wget \
      && \
    npm install -g \
      junit-merge \
      tap-xunit && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    rm -rf /var/lib/apt/lists/*

USER circleci

RUN curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 60 -L "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/""google-cloud-sdk-206.0.0-linux-x86_64.tar.gz" | tar xz && \
    CLOUDSDK_CORE_DISABLE_PROMPTS=1 ./google-cloud-sdk/install.sh \
        --usage-reporting false \
        --bash-completion false \
        --path-update false \
        --rc-path "/home/circleci/.bashrc" && \
    gcloud --quiet components update && \
    gcloud --quiet components update kubectl
