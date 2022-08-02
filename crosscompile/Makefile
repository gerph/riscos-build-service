# 'Cross-compile' makefile for building the Docker container for our environment.
#

ROOT_DIR:=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))

# Version of the pyromaniac-build container we are based on.
PYROMANIAC_BUILD_VERSION ?= 0.38.3303

ifeq (${CI_BRANCH_VERSION},)
DOCKER_TAG = latest
else
DOCKER_TAG = ${CI_BRANCH_VERSION}-${PYROMANIAC_BUILD_VERSION}
endif

cross_install: docker
	@echo Docker container built

docker: prepare
	DOCKER_BUILDKIT=1 docker build --build-arg PYROMANIAC_BUILD_VERSION=${PYROMANIAC_BUILD_VERSION} -t "gerph/robuild-service:${DOCKER_TAG}" ${ROOT_DIR}
	bash -c 'if [[ "${CI_BRANCH}" == "master" && ! "${CI_BRANCH_VERSION}" =~ -dirty ]] ; then ./tag-and-push gerph/robuild-service ${DOCKER_TAG} ${CI_BRANCH} ; fi'

release:

prepare: dirs
clean:
	-rm -rf pyromaniac riscos

dirs:
