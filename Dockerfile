# Using cpantesters/schema until the old database is migrated
FROM cpantesters/schema
#FROM perl:5.42

# Default debian image tries to clean APT after an install. We're using
# cache mounts instead, so we do not want to clean it.
RUN rm -f /etc/apt/apt.conf.d/docker-clean

# Adding s3cmd to upload to object storage more efficiently
# Adding strace to help diagnose forked child processes never exiting
RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  apt-get update && apt-get install -y --no-install-recommends \
    s3cmd strace

RUN mkdir -p /app
WORKDIR /app

ADD cpanfile ./
RUN --mount=type=cache,target=/root/.cpanm \
  cpanm -v --installdeps --notest .

ADD ./ ./
EXPOSE 3000
CMD perl -Ilib script/collector daemon
