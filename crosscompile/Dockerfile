FROM gerph/pyromaniac

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
