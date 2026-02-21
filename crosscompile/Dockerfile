ARG PYROMANIAC_BUILD_VERSION=unset

### Take from the gerph/pyromaniac-build container which has Pyromaniac preconfigured
FROM docker-registry.gerph.org/gerph/pyromaniac-build:${PYROMANIAC_BUILD_VERSION}


### JFPatch
ADD --chown=riscos:riscos riscos/jfpatch/ \
                          /home/riscos/fs/Library/JFPatchResources/
ADD --chown=riscos:riscos riscos/jfpatch-libs/ \
                          /home/riscos/fs/Library/JFPatchResources/Libraries/
ADD --chown=riscos:riscos fs/jfpatch,feb /home/riscos/fs/Library/JFPatch,feb
ADD --chown=riscos:riscos *.pyro \
                          robuild-pyro \
                          /home/riscos/


#### P2C libraries
# FIXME: Get these from artifactory.
ADD --chown=riscos:riscos p2c/libs /home/riscos/fs/Libs/C/p2c
ADD --chown=riscos:riscos p2c/tools /home/riscos/fs/Library


#### Add our modules that we will need
# Not required as they're installed by the container.
#ADD --chown=riscos:riscos riscos/modules/*,ffa /home/riscos/fs/modules/


# Update Pyromaniac with our version
#ADD update/pyromaniac /pyromaniac/pyromaniac-resources/pyromaniac
#ADD update/riscos /pyromaniac/pyromaniac-resources/riscos
#ADD update/pyro.py /pyromaniac/pyromaniac-resources/pyro.py

ENV PYTHONUNBUFFERED=1

ENV HOME="/home/riscos"
USER riscos
