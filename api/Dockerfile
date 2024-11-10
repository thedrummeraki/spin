FROM ruby:3.3.3 as setup
RUN apt-get update && apt-get install -y libpq-dev build-essential
RUN gem install bundler:2.4.10

FROM setup as build
ENV BUNDLE_PATH=/gems
VOLUME [ "/gems" ]
WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
COPY entrypoint.sh /usr/bin
RUN chmod +x /usr/bin/entrypoint.sh

FROM build as dev
RUN apt-get update
RUN apt-get install -y nano iputils-ping
RUN bundle config set --local without production
RUN bundle install --jobs 4 --retry 5
COPY . /app
COPY ./keys/id_rsa.pub /root/.ssh/id_rsa.pub
ENTRYPOINT [ "entrypoint.sh" ]
CMD ["bin/rails", "server", "-b", "0.0.0.0"]

FROM build as live
ENV RAILS_ENV=production
ENV RACK_ENV=production
ENV RAILS_LOG_TO_STDOUT enabled
RUN bundle config set --local without development test
RUN bundle install --jobs 4 --retry 5
COPY . /app
COPY ./keys/id_rsa.pub /root/.ssh/id_rsa.pub
ENTRYPOINT [ "entrypoint.sh" ]
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
