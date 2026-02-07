# By default, Makefiles are executed with /bin/sh, which may not support certain
# features like `$(shell ...)` or `$(if ...)`. To ensure compatibility, we
# explicitly set the shell to bash.
SHELL := /bin/bash

# Set bash shell flags for strict error handling
# -e: Exit immediately if a command exits with a non-zero status.
# -u: Treat unset variables as an error and exit immediately.
# -o pipefail: Make pipelines (e.g. `printenv | sort` ) fail if any command in the pipeline fails.
# -c: read the command from the following string (required).
.SHELLFLAGS := -euo pipefail -c

# Optionally enable the `.ONESHELL` feature, which allows all commands in a recipe to be
# executed in the same shell instance. This is useful for maintaining state
# across commands, such as variable assignments or conditional checks.
#.ONESHELL:

# Set the default goal that will run when just invoking `make`
.DEFAULT_GOAL := vendor/autoload.php

# Detect if we are in a TTY
IS_TTY := $(shell [ -t 1 ] && echo 1 || echo 0)

BUILD_DIRS = build \
	build/.phpunit.cache \
	build/composer \
	build/phpstan \
	build/phpunit \
	build/rector \
	build/xdebug

$(BUILD_DIRS):
	mkdir -p "$@"

DOCKER_IMAGE_TAG ?= wickedbyte/library-skeleton
DOCKER_PLATFORM ?= linux/amd64
DOCKER_PHP_VERSION ?= 8.5
DOCKER_BAKE_OPTIONS ?=
ifeq ($(shell uname -s),Darwin)
  DOCKER_UID ?= 1000
  DOCKER_GID ?= 1000
else
  DOCKER_UID ?= $(shell id -u)
  DOCKER_GID ?= $(shell id -g)
endif
DOCKER_USER ?= "$(DOCKER_UID):$(DOCKER_GID)"
DOCKER_RUN_PULL_IMAGE ?= missing
DOCKER_RUN_IMAGE ?= $(DOCKER_IMAGE_TAG)
DOCKER_RUN_FLAGS = --rm $(if $(IS_TTY),--tty) --pull="$(DOCKER_RUN_PULL_IMAGE)" --volume="./:/app"

docker-run = docker run $(DOCKER_RUN_FLAGS) --user=$(DOCKER_USER) $(DOCKER_RUN_IMAGE)
docker-run-tty = docker run --rm -it --user $$(id -u):$$(id -g) --volume ./:/app $(DOCKER_IMAGE_TAG)

DOCKER_STAMP := build/docker.json

$(DOCKER_STAMP): Dockerfile | $(BUILD_DIRS)
build/docker.json:
	docker buildx build --pull --load \
		--tag wickedbyte/library-skeleton \
		--file Dockerfile \
		--metadata-file $(DOCKER_STAMP) \
		--platform $(DOCKER_PLATFORM) \
		--build-arg PHP_VERSION=$(DOCKER_PHP_VERSION) \
		--build-arg USER_UID=$(DOCKER_UID) \
		--build-arg USER_GID=$(DOCKER_GID) \
		 $(DOCKER_BAKE_OPTIONS) .

vendor/autoload.php: composer.json composer.lock| $(DOCKER_STAMP)
	$(docker-run)  composer install

.PHONY: upgrade-dev
upgrade-dev : vendor/autoload.php
	$(docker-run) composer require --dev -W \
		"php-parallel-lint/php-parallel-lint" \
		"phpstan/extension-installer" \
		"phpstan/phpstan" \
		"phpstan/phpstan-phpunit" \
		"phpunit/phpunit" \
		"rector/rector" \
		"wickedbyte/coding-standard"
	$(docker-run) composer bump --dev-only

.PHONY: clean
clean:
	rm -rf ./build ./vendor

.PHONY: bash
bash: DOCKER_RUN_FLAGS += --interactive
bash: build
	$(docker-run) bash

.PHONY: audit
audit: vendor/autoload.php
	$(docker-run) composer audit

.PHONY: lint phpcbf phpcs phpstan phpunit phpunit-coverage rector rector-dry-run
lint phpcbf phpcs phpstan phpunit phpunit-coverage rector rector-dry-run: vendor/autoload.php
	$(docker-run) composer run-script "$@"

# Runs all the code quality checks: lint, phpstan, phpcs, and rector-dry-run".
.PHONY: ci
ci: lint phpcs phpstan rector-dry-run phpunit audit

# Runs the automated fixer tools, then run the code quality checks in one go, aliased to "preci".
.PHONY: pre-ci preci
preci pre-ci: build phpcbf rector ci

# Run the PHP development server to serve the HTML test coverage report on port 8000 by default
COVERAGE_HTTP_PORT ?= 8000
.PHONY: serve-coverage
serve-coverage: vendor/autoload.php
	@docker compose run --rm --publish $(COVERAGE_HTTP_PORT):80 php php -S 0.0.0.0:80 -t /app/build/phpunit

##------------------------------------------------------------------------------
# Enable Makefile Overrides
#
# If a "build/Makefile" exists, it can define additional targets/behavior and/or
# override the targets of this Makefile. Note that this declaration has to occur
# at the end of the file in order to effect the override behavior.
##------------------------------------------------------------------------------

-include build/Makefile
-include .local/Makefile
