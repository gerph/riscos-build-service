# 'Cross-compile' makefile for building the Docker container for our environment.
#

ROOT_DIR:=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))

# Version of the pyromaniac-build container we are based on.
PYROMANIAC_BUILD_VERSION ?= 0.82.4950

# This is here until we get around to putting it into the -build image.
RO64_BASIC_VERSION = 0.03
RO64_BASIC_URL = https://github.com/gerph/riscos64-rtrussell-bbcbasic/releases/download/v${RO64_BASIC_VERSION}/RISCOS64-BASIC-${RO64_BASIC_VERSION}.zip

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

prepare: dirs ro64/basic,ff8
clean:
	-rm -rf pyromaniac riscos ro64

dirs:


# 64bit binaries
ro64/basic-${RO64_BASIC_VERSION}.zip:
	mkdir -p ro64
	curl --location -o ro64/basic-${RO64_BASIC_VERSION}.zip "${RO64_BASIC_URL}"

ro64/basic,ff8: ro64/basic-${RO64_BASIC_VERSION}.zip
	cd ro64 && unzip -uo basic-${RO64_BASIC_VERSION}.zip
