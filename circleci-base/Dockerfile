FROM circleci/php:7.0-fpm-browsers

MAINTAINER Raymond Walker <raymond.walker@greenpeace.org>

USER root

ENV CIRCLECI_USER 'circleci'
ENV DOCKER_COMPOSE_VERSION '1.16.1'
ENV GOOGLE_SDK_VERSION='174.0.0'
ENV ACK_VERSION='2.18'

WORKDIR /home/circleci

COPY ./scripts /home/circleci/scripts
COPY ./etc/apt/sources.list /etc/apt/sources.list

RUN curl https://beyondgrep.com/ack-${ACK_VERSION}-single-file > /usr/local/bin/ack && chmod 0755 /usr/local/bin/ack && \
    curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose && \
    chmod 755 /usr/local/bin/docker-compose && \
    chmod 755 /home/circleci/scripts/* && \
    apt-get update && apt-get install -y \
      gettext \
      shellcheck && \
    rm -fr /var/lib/apt

USER circleci

RUN git clone https://github.com/sstephenson/bats.git && \
    ./bats/install.sh /usr/local && \
    rm -fr /home/circleci/bats && \
    curl -L "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/""google-cloud-sdk-${GOOGLE_SDK_VERSION}-linux-x86_64.tar.gz" | tar xz && \
    CLOUDSDK_CORE_DISABLE_PROMPTS=1 ./google-cloud-sdk/install.sh \
        --usage-reporting false \
        --bash-completion false \
        --path-update false \
        --rc-path /home/${CIRCLECI_USER}/.bashrc && \
    google-cloud-sdk/bin/gcloud --quiet components update && \
    google-cloud-sdk/bin/gcloud --quiet components update kubectl
