FROM circleci/php:7

MAINTAINER Raymond Walker <raymond.walker@greenpeace.org>

USER root

ENV CIRCLECI_USER 'circleci'
ENV DOCKER_COMPOSE_VERSION '1.16.1'
ENV GOOGLE_SDK_VERSION='174.0.0'

WORKDIR /home/circleci

RUN curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose && \
    apt-get update && apt-get install -y gettext && \
    rm -fr /var/lib/apt

USER circleci

RUN curl -L "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/""google-cloud-sdk-${GOOGLE_SDK_VERSION}-linux-x86_64.tar.gz" | tar xz && \
    CLOUDSDK_CORE_DISABLE_PROMPTS=1 ./google-cloud-sdk/install.sh \
        --usage-reporting false \
        --bash-completion false \
        --rc-path /home/${CIRCLECI_USER}/.bashrc \
        --path-update true && \
    google-cloud-sdk/bin/gcloud --quiet components update && \
    google-cloud-sdk/bin/gcloud --quiet components update kubectl

ADD ./scripts /home/circleci/scripts
