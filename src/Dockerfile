# Planet 4 build container
# https://github.com/greenpeace/planet4-builder
#
# Version: v1.2.18
# Build:   https://circleci.com/gh/greenpeace/planet4-builder#702

# hadolint ignore=DL3007
FROM gcr.io/planet-4-151612/circleci-base:latest

LABEL authors="Raymond Walker <raymond.walker@greenpeace.org>"

RUN helm init --client-only && \
    helm repo add p4 https://planet4-helm-charts.storage.googleapis.com && \
    helm repo add rimusz https://charts.rimusz.net

COPY --chown=circleci:circleci . /home/circleci/
