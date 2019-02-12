# gcr.io/planet-4-151612/circleci-base:v0.7.4
# Base image for performing CI/CD operations in CircleCI
# Branch: v0.7.4
# Commit: 0173d3594cf1153e2074148cd2b5e5559b7c6d20
# Build:  build-1376
# ------------------------------------------------------------------------
#                     DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------

FROM circleci/php:7.0-node

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

LABEL maintainer="Raymond Walker <raymond.walker@greenpeace.org>" \
      description="Base image for performing CI/CD operations in CircleCI"

ENV CIRCLECI_USER=circleci \
    PATH=/home/circleci/scripts:/home/circleci/google-cloud-sdk/bin:${PATH}

USER root

RUN apt-get install -y --no-install-recommends \
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
    rm -rf /tmp/* && \
    rm -rf /var/lib/apt/lists/*

RUN pip install \
      yamllint==1.14.0 \
      yq==2.7.2

RUN npm install -g \
      bats@1.1.0 \
      junit-merge@2.0.0 \
      tap-xunit@2.3.0

WORKDIR /home/circleci

COPY --chown=circleci:circleci .curlrc /home/circleci

RUN mkdir -p scripts && \
    echo "Git Flow v1.11.0 ..." && \
    curl https://raw.githubusercontent.com/petervanderdoes/gitflow-avh/develop/contrib/gitflow-installer.sh | bash -s install version 1.11.0 && \
    rm -fr git-flow && \
    chown -R circleci:circleci /usr/local/bin

USER circleci

RUN echo "Hadolint v1.16.0 ..." && \
    curl -sS "https://github.com/hadolint/hadolint/releases/download/v1.16.0/hadolint-Linux-x86_64" -o /usr/local/bin/hadolint && \
    chmod 755 /usr/local/bin/hadolint && \
    echo "Shellcheck v0.6.0 ..." && \
    curl -sS "https://shellcheck.storage.googleapis.com/shellcheck-v0.6.0.linux.x86_64.tar.xz" -o /tmp/shellcheck.tar.xz && \
    tar xf /tmp/shellcheck.tar.xz -C /tmp/ && \
    mv /tmp/shellcheck-v0.6.0/shellcheck /usr/local/bin && \
    echo "Helm v2.12.3 ..." && \
    curl -sS https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash - && \
    rm -rf /tmp/*

RUN curl -sS "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-233.0.0-linux-x86_64.tar.gz" | tar xz && \
    CLOUDSDK_CORE_DISABLE_PROMPTS=1 ./google-cloud-sdk/install.sh \
        --usage-reporting false \
        --bash-completion false \
        --path-update false && \
    gcloud --quiet components update kubectl cloud_sql_proxy && \
    rm -fr /tmp/*

COPY --chown=circleci:circleci ./scripts /home/circleci/scripts
