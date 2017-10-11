
# Planet 4 CircleCI build containers

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/4c9d5b08e9b046cbba9cdcbc9ba8eaf9)](https://www.codacy.com/app/rawalker/planet4-circleci?utm_source=github.com&utm_medium=referral&utm_content=greenpeace/planet4-circleci&utm_campaign=badger)
[![CircleCI](https://circleci.com/gh/greenpeace/planet4-circleci/tree/master.svg?style=shield)](https://circleci.com/gh/greenpeace/planet4-circleci/tree/master)

Performs builds and tests for the Planet 4 web application and associated infrastructure

The base image builds upon the `circleci/php:7.0` image and adds:
-   [gcloud sdk](https://cloud.google.com/sdk/gcloud/) 174.0.0
-   [docker-compose](https://github.com/docker/compose/releases) 1.16.1
-   [shellcheck](https://github.com/koalaman/shellcheck) latest
-   [ack](https://beyondgrep.com/) 2.18
-   [bats](https://github.com/sstephenson/bats) latest

Upstream images are [CircleCI build images](https://github.com/circleci/circleci-images/)

---
Build: https://circleci.com/gh/greenpeace/planet4-circleci/231
