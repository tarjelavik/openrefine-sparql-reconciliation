FROM stain/jena-fuseki
ARG LOAD_FUSEKI_DATA_ON_START

RUN mv /docker-entrypoint.sh /fuseki-docker-entrypoint.sh 

COPY docker-entrypoint.sh /docker-entrypoint.sh

#Copy configuration file such that we dont ave to create marcus-admin service
COPY fuseki.ttl /fuseki/configuration/fuseki.ttl

RUN chmod +x /docker-entrypoint.sh

#Install dos2unix. Needed for Windows OS
RUN echo http://nl.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
    echo http://nl.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories && \
    apk add --no-cache --virtual .build-deps dos2unix  && \
    dos2unix /docker-entrypoint.sh  && \
    apk del .build-deps  && \
    rm -rf /var/cache/apk/*
