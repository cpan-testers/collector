# Using cpantesters/schema until the old database is migrated
FROM cpantesters/schema
#FROM perl:5.42

# Default debian image tries to clean APT after an install. We're using
# cache mounts instead, so we do not want to clean it.
RUN rm -f /etc/apt/apt.conf.d/docker-clean

# Currently there are no Debian packages we need, but I'm leaving this
# here in case one comes up in the future.
#
# RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
#   --mount=type=cache,target=/var/cache/apt,sharing=locked \
#   apt-get update && apt-get install -y --no-install-recommends

RUN mkdir -p /app
WORKDIR /app

ADD cpanfile ./
RUN --mount=type=cache,target=/root/.cpanm \
  cpanm -v --installdeps --notest .

ADD ./ ./
RUN --mount=type=cache,target=/root/.cpanm \
  cpanm -v --notest .

EXPOSE 3000
CMD perl -Ilib script/collector daemon
