FROM ruby:4.0.3

RUN apt-get update && apt-get install -y postgresql-client vim git

RUN gem install pg

WORKDIR /backend
COPY . .
RUN bundle install