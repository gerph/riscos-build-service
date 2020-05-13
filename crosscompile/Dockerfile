FROM ubuntu:18.04

ENV LANG en_US.UTF-8

RUN echo "Last update: 2020-05-13" && \
    apt-get update && apt-get install -y bash nano

##### Set up the tools we need
RUN apt-get install -y \
            python \
            python-pip \
            virtualenv
RUN pip install --upgrade pip
RUN pip install capstone \
                netifaces && \
    rm -rf .cache/pip


##### Install Pyromaniac
ADD pyromaniac/pyromaniac-resources /pyromaniac/pyromaniac-resources
ADD pyromaniac/pyro /pyromaniac/pyro

ENV PATH="/pyromaniac:$PATH"

# Install all the components into a virtualenv, and ensure that pyromaniac is working
RUN /pyromaniac/pyro --version



# Add user we're going to run under (without a password)
RUN adduser riscos
RUN mkdir -p /home/riscos/fs /home/riscos/fs/tmp /home/riscos/fs/sources/o /home/riscos/fs/sources/h && \
    chown -R riscos:riscos /home/riscos/fs


#### Add RISC OS build environment
# FIXME: We only import the C libs right now - no assembler headers, etc.
ADD --chown=riscos:riscos riscos/build/Lib/CLib /home/riscos/fs/dev
# FIXME: Makefiles aren't being used just yet

# FIXME: We haven't actually got the RISC OS build tools in Artifactory yet, it seems.
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
ADD --chown=riscos:riscos p2c/libs /home/riscos/fs/dev/p2c
ADD --chown=riscos:riscos p2c/tools /home/riscos/fs/Library


#### Add our modules that we will need
ADD --chown=riscos:riscos riscos/modules/*,ffa /home/riscos/fs/modules/



# Create the application and workspace
RUN mkdir -p /home/riscos/fs/tmp && \
    chown riscos:riscos /home/riscos/fs/tmp
RUN mkdir /home/riscos/fs/work && \
    chown riscos:riscos /home/riscos/fs/work
ADD --chown=riscos:riscos fs/!JFPatch /home/riscos/fs/!JFPatch
ADD --chown=riscos:riscos fs/jfpatch,fd1 /home/riscos/fs/Library/jfpatch,fd1
ADD --chown=riscos:riscos *.pyro /home/riscos/

# Update Pyromaniac with our version
#ADD update/pyromaniac /pyromaniac/pyromaniac-resources/pyromaniac
#ADD update/riscos /pyromaniac/pyromaniac-resources/riscos
#ADD update/pyro.py /pyromaniac/pyromaniac-resources/pyro.py

ENV PYTHONUNBUFFERED=1

RUN chmod -R a+rw /home/riscos/fs/tmp && \
    chmod -R a+r /home/riscos/fs
