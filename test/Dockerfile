FROM registry.gitlab.com/modioab/base-image/fedora-31/python:master

ARG URL=unknown
ARG COMMIT=unknown
ARG BRANCH=unknown
ARG HOST=unknown
ARG DATE=unknown

LABEL "se.modio.ci.url"=$URL "se.modio.ci.branch"=$BRANCH "se.modio.ci.commit"=$COMMIT "se.modio.ci.host"=$HOST "se.modio.ci.date"=$DATE

ADD container-script.py /

CMD ["/usr/bin/python3", "/container-script.py"]
