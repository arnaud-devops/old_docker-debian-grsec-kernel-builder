FROM debian:sid

ARG LINUX_VERSION=4.9.16
ARG GRSEC_VERSION=3.1-4.9.16-201703180820
ARG LINUX_CONFIG_VERSION=4.9.8

ARG GPG_LINUX="647F 2865 4894 E3BD 4571  99BE 38DB BDC8 6092 693E"
ARG GPG_GRSEC="DE94 52CE 46F4 2094 907F  108B 44D1 C0F8 2525 FE49"

COPY config-${LINUX_CONFIG_VERSION}-grsec /tmp/
COPY change-default-console-loglevel.patch /tmp/

RUN apt-get update \
    && apt-get -y dist-upgrade \
    && apt-get install -y --no-install-recommends --no-install-suggests build-essential wget gpg dirmngr ca-certificates bc exuberant-ctags libssl-dev \
    && cd /tmp \
    && wget -q https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-${LINUX_VERSION}.tar.xz \
    && wget -q https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-${LINUX_VERSION}.tar.sign \
    && wget -q https://grsecurity.net/test/grsecurity-${GRSEC_VERSION}.patch \
    && wget -q https://grsecurity.net/test/grsecurity-${GRSEC_VERSION}.patch.sig \
    && wget -q https://grsecurity.net/spender-gpg-key.asc \
    && unxz linux-${LINUX_VERSION}.tar.xz \
    && gpg --import spender-gpg-key.asc \
    && gpg --keyserver hkp://keys.gnupg.net --recv-keys 647F28654894E3BD457199BE38DBBDC86092693E \
    && FINGERPRINT_LINUX="$(LANG=C gpg --verify linux-${LINUX_VERSION}.tar.sign linux-${LINUX_VERSION}.tar 2>&1 \
    | sed -n "s#Primary key fingerprint: \(.*\)#\1#p")" \
    && if [ -z "${FINGERPRINT_LINUX}" ]; then echo "linux-${LINUX_VERSION}.tar: Warning! Invalid GPG signature!" && exit 1; fi \
    && if [ "${FINGERPRINT_LINUX}" != "${GPG_LINUX}" ]; then echo "linux-${LINUX_VERSION}.tar: Warning! Wrong GPG fingerprint!" && exit 1; fi \
    && echo "All seems good, now unpacking linux-${LINUX_VERSION}.tar..." \
    && tar -xf linux-${LINUX_VERSION}.tar \
    && FINGERPRINT_GRSEC="$(LANG=C gpg --verify grsecurity-${GRSEC_VERSION}.patch.sig grsecurity-${GRSEC_VERSION}.patch 2>&1 \
    | sed -n "s#Primary key fingerprint: \(.*\)#\1#p")" \
    && if [ -z "${FINGERPRINT_GRSEC}" ]; then echo "grsecurity-${GRSEC_VERSION}.patch: Warning! Invalid GPG signature!" && exit 1; fi \
    && if [ "${FINGERPRINT_GRSEC}" != "${GPG_GRSEC}" ]; then echo "grsecurity-${GRSEC_VERSION}.patch: Warning! Wrong GPG fingerprint!" && exit 1; fi \
    && echo "All seems good, now patching linux-${LINUX_VERSION} with grsecurity-${GRSEC_VERSION}.patch..." \
    && cd linux-${LINUX_VERSION} \
    && patch -p1 < ../change-default-console-loglevel.patch \
    && patch -p1 < ../grsecurity-${GRSEC_VERSION}.patch \
    && cp ../config-${LINUX_CONFIG_VERSION}-grsec .config \
    && make olddefconfig \
    && make -j "$(nproc)" deb-pkg \
    && mkdir /root/linux-kernel \
    && mv /tmp/*.deb /root/linux-kernel/ \
    && apt-get purge -y build-essential gpg wget dirmngr ca-certificates bc exuberant-ctags libssl-dev \
    && apt-get autoremove --purge -y && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/*
