
# Planet 4 CircleCI build containers

[![CircleCI Build Status](https://circleci.com/gh/greenpeace/planet4-circleci.svg?style=shield)]

Performs builds and tests for the Planet 4 web application and associated infrastructure

The base image builds upon the `circleci/php:7.0-fpm-browsers` image and includes:
-   [gcloud sdk](https://cloud.google.com/sdk/gcloud/) 174.0.0
-   [docker-compose](https://github.com/docker/compose/releases) 1.16.1
-   [shellcheck](https://github.com/koalaman/shellcheck) latest

Upstream images are [CircleCI build images](https://github.com/circleci/circleci-images/) and contain:
-   [firefox](https://www.mozilla.org/en-US/firefox/new/) 47.0.0.1
-   [php-fpm](https://php-fpm.org/) v7.0
-   [phantomjs](http://phantomjs.org/) latest
-   [chromedriver](https://sites.google.com/a/chromium.org/chromedriver/) latest
-   [openjdk & openjre](https://sites.google.com/a/chromium.org/chromedriver/) v8
