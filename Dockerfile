FROM perl:5.40

# Default debian image tries to clean APT after an install. We're using
# cache mounts instead, so we do not want to clean it.
RUN rm -f /etc/apt/apt.conf.d/docker-clean

RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  apt-get update && apt-get install -y --no-install-recommends \
    squashfs-tools

RUN mkdir /app
WORKDIR /app

ADD cpanfile ./
RUN --mount=type=cache,target=/root/.cpanm \
  cpanm -v --installdeps --notest .

ADD ./ ./
RUN --mount=type=cache,target=/root/.cpanm \
  cpanm -v --notest .

EXPOSE 3000
CMD perl -Ilib script/collector daemon
