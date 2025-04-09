FROM ruby:3.3.8-bookworm

LABEL org.opencontainers.image.source=https://github.com/sirtony/rotax
LABEL org.opencontainers.image.description="Ruby-based cron alternative."
LABEL org.opencontainers.image.licenses=MIT
LABEL maintainer=sirtony

RUN apt-get update && apt-get upgrade -y

VOLUME /scripts
WORKDIR /rotax

COPY Gemfile ./

RUN gem update --system
RUN bundle install

COPY *.rb ./

ENTRYPOINT [ "ruby", "./rotax.rb" ]
