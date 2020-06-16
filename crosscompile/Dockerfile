FROM ubuntu:18.04

ENV LANG en_US.UTF-8

##### Set up the tools we need
RUN echo "Last update: 2020-06-16" && \
    apt-get update && apt-get install -y bash nano && \
    apt-get install -y \
            python \
            python-pip \
            python-virtualenv && \
    pip install --upgrade pip && \
    pip install capstone \
                netifaces && \
    apt-get remove -y build-essential libc6-dev && apt-get autoremove -y && \
    rm -rf ~/.cache/pip /var/lib/apt/lists



##### Install Pyromaniac
ADD pyromaniac/pyromaniac-resources /pyromaniac/pyromaniac-resources
ADD pyromaniac/pyro /pyromaniac/pyro

ENV PATH="/pyromaniac:$PATH"

# Install all the components into a virtualenv, and ensure that pyromaniac is working
RUN /pyromaniac/pyro --version && \
    rm -rf ~/.cache/pip



# Add user we're going to run under (without a password)
RUN adduser riscos && \
    mkdir -p /home/riscos/fs /home/riscos/fs/tmp && \
    chown -R riscos:riscos /home/riscos/fs


#### Add RISC OS build environment
# C headers
ADD --chown=riscos:riscos riscos/build/C /home/riscos/fs/Libs/C/Interface
ADD --chown=riscos:riscos riscos/build/Lib/CLib /home/riscos/fs/Libs/C/CLib
ADD --chown=riscos:riscos riscos/build/Lib/Fortify /home/riscos/fs/Libs/C/Fortify
ADD --chown=riscos:riscos riscos/build/Lib/Asm /home/riscos/fs/Libs/C/Asm
ADD --chown=riscos:riscos riscos/build/Lib/GetOpt /home/riscos/fs/Libs/C/GetOpt
ADD --chown=riscos:riscos riscos/build/Lib/tboxlibs /home/riscos/fs/Libs/C/TBoxLibs
ADD --chown=riscos:riscos riscos/build/Lib/RISC_OSLib /home/riscos/fs/Libs/C/RISC_OSLib
ADD --chown=riscos:riscos riscos/build/Lib/OSLib /home/riscos/fs/Libs/C/OSLib
ADD --chown=riscos:riscos riscos/build/Lib/TCPIPLibs /home/riscos/fs/Libs/C/TCPIPLibs
ADD --chown=riscos:riscos riscos/build/Hdr/Global /home/riscos/fs/Libs/Hdr/Global
ADD --chown=riscos:riscos riscos/build/Hdr/Interface /home/riscos/fs/Libs/Hdr/Interface
# Makefiles
ADD --chown=riscos:riscos riscos/build/Makefiles /home/riscos/fs/Libs/Makefiles

#ADD --chown=riscos:riscos riscos-tools /home/riscos/fs/Library

ADD --chown=riscos:riscos riscos/tools/CMunge,ff8 \
                          riscos/tools/Do,ffc \
                          riscos/tools/Finger,ff8 \
                          riscos/tools/GetHost,ff8 \
                          riscos/tools/Help/Do \
                          riscos/tools/Help/Finger \
                          riscos/tools/Help/GetHost \
                          riscos/tools/Help/IFConfig \
                          riscos/tools/Help/IfThere \
                          riscos/tools/Help/Ping \
                          riscos/tools/Help/Pong \
                          riscos/tools/Help/RTime \
                          riscos/tools/Help/X \
                          riscos/tools/IFConfig,ff8 \
                          riscos/tools/IfThere,ffc \
                          riscos/tools/ModServices,ff8 \
                          riscos/tools/perl,ff8 \
                          riscos/tools/Ping,ff8 \
                          riscos/tools/Pong,ff8 \
                          riscos/tools/RTime,ff8 \
                          riscos/tools/ResGen,ff8 \
                          riscos/tools/X,ffc \
                          riscos/tools/amu,ff8 \
                          riscos/tools/bison,ff8 \
                          riscos/tools/cc,ff8 \
                          riscos/tools/flex,ff8 \
                          riscos/tools/libfile,ff8 \
                          riscos/tools/link,ff8 \
                          riscos/tools/objasm,ff8 \
                          riscos/tools/sed,ff8 \
                          riscos/tools/squeeze,ff8 \
                          /home/riscos/fs/Library/


#### P2C libraries
# FIXME: Get these from artifactory.
ADD --chown=riscos:riscos p2c/libs /home/riscos/fs/Libs/p2c
ADD --chown=riscos:riscos p2c/tools /home/riscos/fs/Library


#### Add our modules that we will need
ADD --chown=riscos:riscos riscos/modules/*,ffa /home/riscos/fs/modules/



# Create the application and workspace
RUN mkdir -p /home/riscos/fs/tmp && \
    chown riscos:riscos /home/riscos/fs/tmp && \
    chmod -R a+rw /home/riscos/fs/tmp && \
    mkdir /home/riscos/fs/work && \
    chown riscos:riscos /home/riscos/fs/work

ADD --chown=riscos:riscos fs/!JFPatch /home/riscos/fs/!JFPatch
ADD --chown=riscos:riscos fs/jfpatch,fd1 /home/riscos/fs/Library/jfpatch,fd1
ADD --chown=riscos:riscos *.pyro /home/riscos/

# Update Pyromaniac with our version
#ADD update/pyromaniac /pyromaniac/pyromaniac-resources/pyromaniac
#ADD update/riscos /pyromaniac/pyromaniac-resources/riscos
#ADD update/pyro.py /pyromaniac/pyromaniac-resources/pyro.py

ENV PYTHONUNBUFFERED=1
