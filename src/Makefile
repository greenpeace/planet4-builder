SHELL := /bin/bash

.EXPORT_ALL_VARIABLES:

# https://github.com/greenpeace/planet4-docker
PARENT_IMAGE      ?= gcr.io/planet-4-151612/wordpress
PARENT_VERSION    ?= build-14556

# Wordpress Helm chart version
CHART_VERSION     ?= 0.8.31

# Use current folder name as prefix for built containers,
# eg planet4-gpi-app planet4-gpi-openresty
CONTAINER_PREFIX  ?= planet4-test

################################################################################

# Configure composer source and merge repository data

# Define APP_ENVIRONMENT in case it's not set to development already
APP_ENVIRONMENT     ?= production

# Base composer project repository
# FIXME change this to greenpeace/planet4-base once things are settled
GIT_SOURCE        ?= https://github.com/greenpeace/planet4-base

# The branch to checkout of GIT_SOURCE, eg:
# Use local branch name if not set
GIT_REF           ?= main

# Merge composer project directory (NRO)
MERGE_SOURCE      ?= $(CIRCLE_REPOSITORY_URL)

# The branch to checkout of MERGE_SOURCE, eg:
# Use CIRCLE_TAG > CIRLCE_BRANCH >
MERGE_REF         ?= $(CIRCLE_TAG)

# If the current commit does not have a tag, use the branch
ifeq ($(strip $(MERGE_REF)),)
MERGE_REF         := $(CIRCLE_BRANCH)
endif

# No tag or branch? ...  hope for the best
ifeq ($(strip $(MERGE_REF)),)
MERGE_REF         := $(shell git rev-parse --abbrev-ref HEAD)
endif

################################################################################

# Tag to use on built containers

# Stips away unwanted characters from current branch or tag
BUILD_TAG          ?= $(shell echo $(MERGE_REF) | tr -c '[[:alnum:]]._-' '-' | sed 's/-$$//')

################################################################################
#
# Helm deploy configuration
#
# Default and derived values

APP_HOSTNAME        ?= greenpeace.org
APP_HOSTPATH        ?= test
# YAML interprets 'empty' values as 'nil'
ifeq ($(APP_HOSTPATH),<nil>)
# So if APP_HOSTPATH is set, but blank, clean this value
APP_HOSTPATH :=
endif
BUILD_NAMESPACE     ?= gcr.io
GOOGLE_PROJECT_ID   ?= planet-4-151612
OPENRESTY_IMAGE     ?= $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-openresty
PHP_IMAGE           ?= $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-app

WP_STATELESS_BUCKET ?= $(CONTAINER_PREFIX)-stateless-$(HELM_NAMESPACE)
WP_STATELESS_OWNER  ?= cloudstorage@planet-4-151612.iam.gserviceaccount.com

HELM_NAMESPACE      ?= $(APP_HOSTPATH)
HELM_RELEASE        ?= $(CONTAINER_PREFIX)

PULL_POLICY					?= IfNotPresent

CLOUDSQL_INSTANCE   ?= p4-develop-k8s

GCLOUD_CLUSTER      ?= p4-development
GCLOUD_REGION       ?= us-central1
GCLOUD_ZONE         ?= us-central1-a

PAGESPEED_ENABLED   ?= false

INGRESS_CLASS				?= traefik
INGRESS_NOTLS				?= true
INGRESS_TLS					?= false

CLOUDFLARE_ENABLED  ?= true
ifeq ($(strip $(APP_ENVIRONMENT)),production)
MIN_REPLICA_COUNT 	?= 2
else
MIN_REPLICA_COUNT 	?= 1
endif
MAX_REPLICA_COUNT 	?= 5

PHP_MIN_REPLICA_COUNT ?= $(MIN_REPLICA_COUNT)
PHP_MAX_REPLICA_COUNT ?= $(MAX_REPLICA_COUNT)

OPENRESTY_MIN_REPLICA_COUNT ?= $(MIN_REPLICA_COUNT)
OPENRESTY_MAX_REPLICA_COUNT ?= $(MAX_REPLICA_COUNT)

PHP_PROCESS_MANAGER_MAX_CHILDREN ?= 50
PHP_PROCESS_MANAGER_MAX_REQUESTS ?= 1000
PHP_PROCESS_MANAGER_MAX_SPARE_SERVERS ?= 5
PHP_PROCESS_MANAGER_MIN_SPARE_SERVERS ?= 4
PHP_PROCESS_MANAGER_START_SERVERS ?= 5
PHP_PROCESS_MANAGER ?= dynamic
PHP_MEMORY_LIMIT ?= 1Gi

# Secrets
# Values are expected to be stored in Circle build environment

# SQLPROXY_KEY        := $(SQLPROXY_KEY)
# EXIM_USERNAME       := $(EXIM_USERNAME)
# EXIM_PASSWORD       := $(EXIM_PASSWORD)
# WP_AUTH_KEY         := $(WP_AUTH_KEY)
# WP_AUTH_SALT        := $(WP_AUTH_SALT)
WP_DB_USERNAME      ?= $(CONTAINER_PREFIX)
WP_DB_NAME          ?= $(WP_DB_USERNAME)_wordpress
# WP_DB_PASSWORD      := $(WP_DB_PASSWORD)
# WP_LOGGED_IN_KEY    := $(WP_LOGGED_IN_KEY)
# WP_LOGGED_IN_SALT   := $(WP_LOGGED_IN_SALT)
# WP_NONCE_KEY        := $(WP_NONCE_KEY)
# WP_NONCE_SALT       := $(WP_NONCE_SALT)
# WP_SECURE_AUTH_KEY  := $(WP_SECURE_AUTH_KEY)
# WP_SECURE_AUTH_SALT := $(WP_SECURE_AUTH_SALT)
# WP_STATELESS_KEY    := $(WP_STATELESS_KEY)

FORCE_ACTIVATE_PLUGINS ?= true

################################################################################
#
# Google Cloud Storage Bucket configuration
# Stores built artifacts
#
# GCS bucket to store built source
SOURCE_BUCKET       := $(CONTAINER_PREFIX)-source
SOURCE_BUCKET_PATH  ?= $(BUILD_TAG)

################################################################################


.PHONY: clean test rewrite checkout bake build build-app build-openresty pull push

all: test rewrite checkout rewrite-app-repos copy bake persist build push

dev: clean rewrite checkout rewrite-app-repos copy bake build

ci: rewrite checkout rewrite-app-repos copy bake build

test:
	set -eu
	@echo "Building $(CONTAINER_PREFIX):$(BUILD_TAG) containers..."
	@echo "PARENT_IMAGE:      $(PARENT_IMAGE)"
	@echo "PARENT_VERSION:    $(PARENT_VERSION)"
	@echo "APP_HOSTNAME:      $(APP_HOSTNAME)"
	@echo "APP_HOSTPATH:      $(APP_HOSTPATH)"
	@echo "GIT_REF:           $(GIT_REF)"
	@echo "MERGE_REF:         $(MERGE_REF)"
	@echo ""

clean:
	rm -fr source
	docker-compose -p build down -v

checkout:
	checkout.sh

rewrite-app-repos:
	composer-requirements.py "${HOME}/source/composer.json" "${APP_ENVIRONMENT}"
	composer-requirements.py "${HOME}/merge/composer-local.json" "${APP_ENVIRONMENT}"
	rewrite_app_repos.sh

rewrite:
	rewrite_dockerfiles.sh

copy:
	# Copy source files to build container context
	[[ -d source ]] && rsync --exclude '.git' -a source/ build/source
	# Copy merge files to build container context, overwriting as required
	[[ -d merge ]] && rsync --exclude '.git' -a merge/ build/source
	# Copy release number
	cp /tmp/workspace/release_number build/source/public/

bake:
	source lib/retry.sh && retry bake.sh | tee source/bake.log

persist:
	# Copy the source data in the persistence workspace
	rsync -a --exclude 'cache' build/source/* /tmp/workspace/src

build: rewrite build-app build-openresty

build-app:
	mkdir -p app/source/public
	rsync -a --delete source/public/ app/source/public
	source lib/retry.sh && \
	retry docker pull $(PARENT_IMAGE):$(PARENT_VERSION) && \
	pushd app && \
	retry docker build \
	-t $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-app:$(BUILD_TAG) \
	-t $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-app:build-$(CIRCLE_BUILD_NUM) \
	. && \
	popd

build-openresty:
	rewrite_dockerfiles.sh
	mkdir -p openresty/source/public
	rsync -a --delete source/public/ openresty/source/public
	rsync -av --ignore-missing-args source/built-dev-assets/public openresty/source
	source lib/retry.sh && \
	retry docker pull gcr.io/planet-4-151612/openresty:$(PARENT_VERSION) && \
	pushd openresty && \
	retry docker build \
	-t $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-openresty:$(BUILD_TAG) \
	-t $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-openresty:build-$(CIRCLE_BUILD_NUM) \
	. && \
	popd

push:
	gcloud auth configure-docker
	source lib/retry.sh && \
	retry docker push $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-openresty:$(BUILD_TAG) && \
	retry docker push $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-app:$(BUILD_TAG) && \
	retry docker push $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-openresty:build-$(CIRCLE_BUILD_NUM) && \
	retry docker push $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-app:build-$(CIRCLE_BUILD_NUM)

pull:
	docker pull $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-app:$(BUILD_TAG) &
	docker pull $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-openresty:$(BUILD_TAG) &
	wait

backup:
	backup_db.sh

deploy: prepare-helm deploy-helm post-deploy

rollback: checkout copy persist prepare-helm rollback-helm post-deploy

prepare-helm:
	# Update Helm repositories
	helm3 repo update

	# Connect to cluster
	gcloud container clusters get-credentials $(GCLOUD_CLUSTER) \
	--zone $(GCLOUD_ZONE) \
	--project $(GOOGLE_PROJECT_ID)

rollback-helm:
	# Rollback to the previous good release
	helm_rollback.sh

deploy-helm:
	# Upgrade or install deployment to cluster
	helm_deploy.sh

	# Remove secrets file
	rm -f "$HOME"/secrets.yaml

post-deploy:
	activate_plugins.sh

	flush_redis.sh

	configure_redis.sh

	run_post_deploy_scripts.sh
