FROM perl:5.40

RUN mkdir /app
WORKDIR /app

ADD cpanfile ./
RUN --mount=type=cache,target=/root/.cpanm \
  cpanm -v --installdeps --notest .

ADD ./ ./
RUN --mount=type=cache,target=/root/.cpanm \
  cpanm -v .

EXPOSE 3000
CMD perl -Ilib script/collector daemon
