FROM ruby:3.3.3-slim as setup
RUN apt-get update && apt-get install -y libpq-dev build-essential

FROM setup as build
ENV BUNDLE_PATH=/gems
VOLUME [ "/gems" ]
WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock

RUN bundle install --jobs 4 --retry 5
COPY . /app/

ENTRYPOINT [ "bundle", "exec" ]
