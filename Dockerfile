# * How to build the image
# $ docker build --tag sjikim/phoenix:latest .
#
# * How to run the container
# $ docker run -it --rm -v "$PWD":/phoenix -w /phoenix -p 4000:4000 sjikim/phoenix:latest

FROM ubuntu:15.10

MAINTAINER sjikim

RUN locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

RUN apt-get install -y wget ca-certificates

# Install Elixir and PostgreSQL

## Sets up sources.list to use nearest Ubuntu mirror, adds Erlang Solutions APT repository.
## cf https://www.erlang-solutions.com/resources/download.html
RUN sed -i 's/\/archive.ubuntu.com/\/mirror.optus.net/' /etc/apt/sources.list &&\
    echo deb http://packages.erlang-solutions.com/ubuntu `awk -F= '/DISTRIB_CODENAME/ {print $2}' /etc/lsb-release` contrib >> /etc/apt/sources.list
RUN wget --quiet -O - http://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | apt-key add -
RUN echo 'Package: *' > /etc/apt/preferences &&\
    echo 'Pin: release o=Erlang Solutions Ltd.' >> /etc/apt/preferences &&\
    echo 'Pin-Priority: 999' >> /etc/apt/preferences

RUN apt-get update &&\
  apt-get install -y curl inotify-tools &&\
  apt-get install -y erlang-base-hipe &&\
  apt-get install -y elixir &&\
  apt-get install -y postgresql-9.4

RUN echo "alter user postgres with password 'postgres';" > /tmp/set-pg-password.sql
RUN su - postgres -c 'pg_ctlcluster 9.4 main start && psql -f /tmp/set-pg-password.sql'

# Install Node.js
RUN curl -sL https://deb.nodesource.com/setup_4.x | bash -
RUN apt-get install -y nodejs

# Install Phoenix
ENV phoenix_ver=1.0.4
RUN mix local.hex --force &&\
    mix local.rebar --force &&\
    mix archive.install https://github.com/phoenixframework/phoenix/releases/download/v${phoenix_ver}/phoenix_new-${phoenix_ver}.ez --force

EXPOSE 4000 5432

CMD su - postgres -c 'pg_ctlcluster 9.4 main start'; bash
