FROM ruby:3.2.3

ARG DIR=/scraper

RUN mkdir $DIR
COPY . $DIR
WORKDIR $DIR

RUN mkdir $HOME/tor-browser
RUN tar -xf ./deps/tor-browser.tar.xz -C $HOME/tor-browser

RUN mkdir $HOME/geckodriver
RUN tar -xf ./deps/geckodriver.tar.gz -C $HOME/geckodriver
RUN chmod +x $HOME/geckodriver
RUN export PATH=$PATH:$HOME/geckodriver

RUN bundle install

RUN ruby scraper.rb
