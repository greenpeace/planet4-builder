# Planet 4 CircleCI build image
# Branch: master
# Commit: 49229aa11781ce04e168b8926c25de814d0bd0dd
# Build:  https://circleci.com/gh/greenpeace/planet4-circleci/1271
# ------------------------------------------------------------------------
#                     DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------

FROM circleci/php:7.0-node

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

LABEL maintainer="Raymond Walker <raymond.walker@greenpeace.org>" \
      description="Planet 4 CircleCI build image: \
Base image for performing CI/CD operations in CircleCI"

USER root

ENV CIRCLECI_USER="circleci" \
    PATH="/home/circleci/scripts:/home/circleci/google-cloud-sdk/bin:${PATH}"

WORKDIR /home/circleci

COPY .curlrc /home/circleci

COPY ./scripts /home/circleci/scripts

RUN git clone https://github.com/sstephenson/bats.git && \
    ./bats/install.sh /usr/local && \
    rm -fr /home/circleci/bats && \
    curl -sSL https://github.com/hadolint/hadolint/releases/download/v1.16.0/hadolint-Linux-x86_64 -o /usr/local/bin/hadolint && \
    chmod 755 /usr/local/bin/hadolint && \
    curl -sS "https://shellcheck.storage.googleapis.com/shellcheck-v0.6.0.linux.x86_64.tar.xz" -o /tmp/shellcheck.tar.xz && \
    tar xf /tmp/shellcheck.tar.xz -C /tmp/ && \
    mv /tmp/shellcheck-v0.6.0/shellcheck /usr/local/bin && \
    curl -sS "https://releases.hashicorp.com/terraform/0.11.10/terraform_0.11.10_linux_amd64.zip" > /tmp/terraform.zip && \
    unzip /tmp/terraform.zip -d /usr/local/bin && \
    chmod 0755 /usr/local/bin/terraform && \
    curl -sSLO "https://github.com/gruntwork-io/terragrunt/releases/download/v0.17.2/terragrunt_linux_amd64" && \
    chmod 0755 terragrunt_linux_amd64 && \
    mv terragrunt_linux_amd64 /usr/local/bin/terragrunt && \
    chmod 0755 /home/circleci/scripts/* && \
    export "DESIRED_VERSION=v2.12.3" && \
    curl -sS https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash - && \
    curl -sS https://raw.githubusercontent.com/petervanderdoes/gitflow-avh/develop/contrib/gitflow-installer.sh | bash -s install version 1.11.0 && \
    rm -fr git-flow && \
    curl -s https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 > /usr/local/bin/cloud_sql_proxy && \
    chmod 0755 /usr/local/bin/cloud_sql_proxy && \
    apt-get install -y --no-install-recommends \
      gawk \
      gettext \
      mysql-client \
      python-pip \
      python-pkg-resources \
      python-setuptools \
      silversearcher-ag \
      vim \
      wget \
      && \
    pip install yamllint && \
    npm install -g \
      junit-merge \
      tap-xunit && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    rm -rf /var/lib/apt/lists/*

USER circleci

RUN curl "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-231.0.0-linux-x86_64.tar.gz" | tar xz && \
    CLOUDSDK_CORE_DISABLE_PROMPTS=1 ./google-cloud-sdk/install.sh \
        --usage-reporting false \
        --bash-completion false \
        --path-update false \
        --rc-path "/home/circleci/.bashrc" && \
    gcloud --quiet components update kubectl
