# 'Cross-compile' makefile for building the Docker container for our environment.
#

ROOT_DIR:=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))

# Version of the pyromaniac-build container we are based on.
PYROMANIAC_BUILD_VERSION ?= 0.17.1900

cross_install: docker
	@echo Docker container built

docker: prepare
	DOCKER_BUILDKIT=1 docker build --build-arg PYROMANIAC_BUILD_VERSION=${PYROMANIAC_BUILD_VERSION} -t "gerph/robuild-service:$${CI_BRANCH_VERSION:-latest}" ${ROOT_DIR}
	bash -c 'if [[ "${CI_BRANCH}" == "master" && ! "${CI_BRANCH_VERSION}" =~ -dirty ]] ; then docker tag "gerph/robuild-service:${CI_BRANCH_VERSION}" gerph/robuild-service:latest ; fi'

prepare: dirs
clean:
	-rm -rf pyromaniac riscos

dirs:
