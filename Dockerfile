FROM ruby:2.2.0
RUN apt-get -qqy update && \
    apt-get -qqy install build-essential libpq-dev nodejs
# for amex headless
RUN apt-get -qqy update && \
    apt-get -qqy install xvfb iceweasel
RUN rm -rf /var/lib/apt/lists/*
RUN mkdir /amex
WORKDIR /amex
ADD Gemfile /amex/Gemfile
ADD Gemfile.lock /amex/Gemfile.lock
RUN bundle install
ADD . /amex
