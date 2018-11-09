# Planet 4 CircleCI build image
# Branch: master
# Commit: 99c2d0b9a8ed034f2c63f386bdc09da3508af206
# Build:  https://circleci.com/gh/greenpeace/planet4-circleci/1117
# ------------------------------------------------------------------------
#                     DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------

FROM circleci/php:7.0-node

LABEL maintainer="Raymond Walker <raymond.walker@greenpeace.org>" \
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
    curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 60 "https://releases.hashicorp.com/terraform/0.11.10/terraform_0.11.10_linux_amd64.zip" > /tmp/terraform.zip && \
    unzip /tmp/terraform.zip -d /usr/local/bin && \
    chmod 0755 /usr/local/bin/terraform && \
    curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 60 -sSOL https://github.com/gruntwork-io/terragrunt/releases/download/v0.17.1/terragrunt_linux_amd64 && \
    chmod 0755 terragrunt_linux_amd64 && \
    mv terragrunt_linux_amd64 /usr/local/bin/terragrunt && \
    curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 60 "https://beyondgrep.com/ack-2.24-single-file" > /usr/local/bin/ack && \
    chmod 0755 /usr/local/bin/ack && \
    chmod 0755 /home/circleci/scripts/* && \
    export "DESIRED_VERSION=v2.11.0" && \
    curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 60 -sL https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash - && \
    wget --no-check-certificate -q https://raw.githubusercontent.com/petervanderdoes/gitflow-avh/develop/contrib/gitflow-installer.sh && \
    bash gitflow-installer.sh install stable && \
    rm gitflow-installer.sh && \
    curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 60 -sL https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 > /usr/local/bin/cloud_sql_proxy && \
    chmod 0755 /usr/local/bin/cloud_sql_proxy && \
    apt-get install -y --no-install-recommends \
      gawk \
      gettext \
      mysql-client \
      python-pip \
      python-pkg-resources \
      python-setuptools \
      shellcheck \
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

RUN curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 60 -L "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-223.0.0-linux-x86_64.tar.gz" | tar xz && \
    CLOUDSDK_CORE_DISABLE_PROMPTS=1 ./google-cloud-sdk/install.sh \
        --usage-reporting false \
        --bash-completion false \
        --path-update false \
        --rc-path "/home/circleci/.bashrc" && \
    gcloud --quiet components update kubectl
