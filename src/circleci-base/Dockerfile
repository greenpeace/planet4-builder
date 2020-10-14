# greenpeaceinternational/circleci-base:v0.7.41
# Base image for performing CI/CD operations in CircleCI
# Branch: v0.7.41
# Commit: 051445e2912bb28f7bda067f4d44711e681265f1
# Build:  build-1626
# ------------------------------------------------------------------------
#                     DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------

FROM circleci/php:7.3-node

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

LABEL maintainer="Raymond Walker <raymond.walker@greenpeace.org>" \
      description="Base image for performing CI/CD operations in CircleCI"

ENV CIRCLECI_USER=circleci \
    PATH=/home/circleci/scripts:/home/circleci/google-cloud-sdk/bin:${PATH}

USER root

# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      gawk \
      gettext \
      default-mysql-client \
      python-pip \
      python-pkg-resources \
      python-setuptools \
      rsync \
      silversearcher-ag \
      vim \
      wget \
      && \
    rm -rf /tmp/* && \
    rm -rf /var/lib/apt/lists/*

RUN pip install \
      yamllint==1.23.0 \
      yq==2.10.1

RUN git config --global alias.unstaged 'diff --name-only' && \
    git config --global alias.staged 'diff --name-only --cached'

RUN npm install -g \
      bats@1.1.0 \
      junit-merge@2.0.0 \
      tap-xunit@2.4.1

WORKDIR /home/circleci

COPY --chown=circleci:circleci .curlrc /home/circleci

RUN mkdir -p scripts && \
    echo "Git Flow v1.12.3 ..." && \
    curl https://raw.githubusercontent.com/petervanderdoes/gitflow-avh/develop/contrib/gitflow-installer.sh | bash -s install version 1.12.3 && \
    rm -fr git-flow && \
    chown -R circleci:circleci /usr/local/bin

USER circleci

RUN echo "Hadolint v1.18.0 ..." && \
    curl -sS "https://github.com/hadolint/hadolint/releases/download/v1.18.0/hadolint-Linux-x86_64" -o /usr/local/bin/hadolint && \
    chmod 755 /usr/local/bin/hadolint && \
    echo "Shellcheck v0.7.1 ..." && \
    curl -sS "https://github.com/koalaman/shellcheck/releases/download/v0.7.1/shellcheck-v0.7.1.linux.x86_64.tar.xz" -o /tmp/shellcheck.tar.xz && \
    tar xf /tmp/shellcheck.tar.xz -C /tmp/ && \
    mv /tmp/shellcheck-v0.7.1/shellcheck /usr/local/bin && \
    echo "Helm v2.16.9 ..." && \
    curl -sS "https://storage.googleapis.com/kubernetes-helm/helm-v2.16.9-linux-amd64.tar.gz" -o /tmp/helm.tar.gz && \
    tar zxf /tmp/helm.tar.gz -C /tmp/ && \
    mv /tmp/linux-amd64/helm /usr/local/bin/helm && \
    echo "Trivy v0.11.1 ..." && \
    curl -sSL https://github.com/knqyf263/trivy/releases/download/v0.11.1/trivy_0.11.1_Linux-64bit.tar.gz -o /tmp/trivy.tar.gz && \
    tar zxvf /tmp/trivy.tar.gz -C /tmp/ && \
    mv /tmp/trivy /usr/local/bin && \
    echo "Shfmt v3.1.2 ..." && \
    curl -sSfL https://github.com/mvdan/sh/releases/download/v3.1.2/shfmt_v3.1.2_linux_amd64 -o /usr/local/bin/shfmt && \
    chmod +x /usr/local/bin/shfmt && \
    rm -rf /tmp/*

RUN curl -sS "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-299.0.0-linux-x86_64.tar.gz" | tar xz && \
    CLOUDSDK_CORE_DISABLE_PROMPTS=1 ./google-cloud-sdk/install.sh \
        --usage-reporting false \
        --bash-completion false \
        --path-update false && \
    gcloud --quiet components update kubectl cloud_sql_proxy && \
    rm -fr /tmp/*

COPY --chown=circleci:circleci ./bin /home/circleci/bin

COPY --chown=circleci:circleci ./scripts /home/circleci/scripts
