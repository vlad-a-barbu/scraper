FROM ruby:3.2.3

RUN apt update -y \
    && apt install -y wget firefox-esr xvfb # xvfb for headless

ARG WORKDIR=/scraper

ARG TORVERSION="13.0.11"
ARG TORURL="https://www.torproject.org/dist/torbrowser/$TORVERSION/tor-browser-linux-x86_64-$TORVERSION.tar.xz"

ARG GECKOVERSION="0.34.0"
ARG GECKOURL="https://github.com/mozilla/geckodriver/releases/download/v$GECKOVERSION/geckodriver-v$GECKOVERSION-linux64.tar.gz"

WORKDIR $WORKDIR
COPY . $WORKDIR

RUN wget $TORURL -O tor-browser.tar.xz
RUN tar -xf tor-browser.tar.xz -C $HOME

RUN wget $GECKOURL -O geckodriver.tar.gz
RUN sh -c 'tar -x geckodriver -zf geckodriver.tar.gz -O > /usr/bin/geckodriver'
RUN chmod +x /usr/bin/geckodriver

RUN bundle install
