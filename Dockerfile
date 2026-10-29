FROM ruby:3.4.11
WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .