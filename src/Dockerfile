FROM gcr.io/planet-4-151612/circleci-base:latest

LABEL authors="Raymond Walker <raymond.walker@greenpeace.org>"

RUN helm init --client-only && \
    helm repo add p4-helm-charts https://p4-helm-charts.storage.googleapis.com

COPY --chown=circleci:circleci . /home/circleci/
