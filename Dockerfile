ARG BASE_IMAGE_PREFIX

FROM multiarch/qemu-user-static as qemu

FROM ${BASE_IMAGE_PREFIX}alpine

COPY --from=qemu /usr/bin/qemu-*-static /usr/bin/
COPY scripts/start.sh /
COPY guacamole-server /tmp/guacamole-server

# Environment variables
ARG GUACD_Version
ENV GUACD_Version=${GUACD_Version}
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}/usr/local/lib"
ENV C_INCLUDE_PATH="${C_INCLUDE_PATH:+$C_INCLUDE_PATH:}/usr/local/include"

ENV GUACD_RUN_DEPS="cairo ffmpeg-libs glib libcrypto1.1 libjpeg-turbo libpng libpulse libssh2 libssl1.1 libvncserver libwebp libwebsockets musl pango libvorbis libpulse ttf-inconsolata"
ENV GUACD_RUN_DEPS_TESTING="ossp-uuid freerdp"
ENV Common_BUILD_DEPS="curl autoconf automake gcc libtool cmake make fontconfig"

ENV GUACD_BUILD_DEPS="cairo-dev ffmpeg-dev glib-dev libjpeg-turbo-dev libpng-dev libssh2-dev libvncserver-dev libwebp-dev libwebsockets-dev musl-dev pango-dev pulseaudio-dev libvorbis-dev"
ENV GUACD_BUILD_DEPS_TESTING="ossp-uuid-dev freerdp-dev"


###### Install & Download Prerequisites ######
RUN apk -U --no-cache upgrade
RUN apk add --no-cache --virtual=.build-dependencies $GUACD_BUILD_DEPS $Common_BUILD_DEPS
RUN apk add --no-cache --virtual=.build-dependencies_testing $GUACD_BUILD_DEPS_TESTING --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing
RUN apk add --no-cache $GUACD_RUN_DEPS
RUN apk add --no-cache $GUACD_RUN_DEPS_TESTING --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing

WORKDIR /tmp/guacamole-server
RUN autoreconf -fi
RUN ./configure
RUN make
RUN make install
RUN apk del .build-dependencies
RUN apk del .build-dependencies_testing
WORKDIR /
RUN chmod +x /start.sh

RUN rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* /usr/bin/qemu-*-static

# ports and volumes
EXPOSE 4822

CMD [ "/start.sh" ]
