FROM chambana/base:latest

MAINTAINER Josh King <jking@chambana.net>

ENV PROSODY_DB_HOST="postgres" PROSODY_DB_PORT="5432" PROSODY_DB_USER="prosody" \
    PROSODY_DB_NAME="prosody" PROSODY_LDAP_HOST="ldap" PROSODY_LDAP_GROUP="xmpp" \
    PROSODY_ADMINS=""

RUN apt-get -qq update && \
    apt-get install -y --no-install-recommends postgresql-client \
                                               lua5.1 \
                                               liblua5.1-dev \
                                               lua-bitop \
                                               lua-bitop-dev \
                                               lua-sec \
                                               lua-ldap \
                                               lua-dbi-postgresql \
                                               lua-expat \
                                               lua-socket \
                                               lua-filesystem \
                                               lua-zlib \
                                               lua-ldap \
                                               lua-event \
                                               libidn11-dev \
                                               libssl-dev \
                                               mercurial \
                                               bsdmainutils \
                                               wget \
                                               openssl \
                                               ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN groupadd prosody
RUN useradd -g prosody prosody

RUN wget http://packages.prosody.im/debian/pool/main/p/prosody-0.10/prosody-0.10_1nightly198-1~jessie_amd64.deb
RUN dpkg -i prosody-0.10_1nightly198-1~jessie_amd64.deb
RUN hg clone https://hg.prosody.im/prosody-modules/ prosody-modules

RUN cp -rf prosody-modules/* /usr/lib/prosody/modules/

# Workaround for library path issues
RUN cp prosody-modules/mod_lib_ldap/ldap.lib.lua /usr/lib/prosody/modules/

# Cleanup
RUN rm -rf prosody-modules 

RUN mkdir -p /etc/prosody/conf.d /var/log/prosody /var/run/prosody

ADD files/prosody/prosody.cfg.lua /etc/prosody/prosody.cfg.lua
ADD files/prosody/prosody-ldap.cfg.lua /etc/prosody/prosody-ldap.cfg.lua

RUN chown -R prosody:prosody /etc/prosody /var/lib/prosody /var/log/prosody /var/run/prosody

EXPOSE 5000 5222 5269 5347 5280 5281

## Add startup script.
ADD bin/run.sh /app/bin/run.sh
RUN chmod 0755 /app/bin/run.sh

ENTRYPOINT ["/app/bin/run.sh"]
CMD ["su", "-", "prosody", "-c", "/usr/bin/prosody"]
