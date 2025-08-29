FROM ruby:3.3.7

RUN apt-get update && apt-get install -y postgresql-client vim git

RUN gem install pg

WORKDIR /backend
COPY . .
RUN bundle install