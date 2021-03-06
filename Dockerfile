FROM ruby:2.6.6-buster

WORKDIR /

# Public key download locations
# chrome.pub             https://dl-ssl.google.com/linux/linux_signing_key.pub
# node.pub               https://deb.nodesource.com/gpgkey/nodesource.gpg.key
# postgres.pub           https://www.postgresql.org/media/keys/ACCC4CF8.asc
# yarn.pub               https://dl.yarnpkg.com/debian/pubkey.gpg

# Add SHA256 sum for ChromeDriver binary.
# Calculate with: curl -s DOWNLOAD_URL | shasum -a 256
# ChromeDriver v2.41 https://chromedriver.storage.googleapis.com/2.41/chromedriver_linux64.zip
ADD chromedriver.sha256 /chromedriver.sha256

# Install basic utilities for package installation and setup.
RUN apt-get update && apt-get upgrade -y
RUN apt-get install sudo apt-transport-https -y

# Set locale
RUN apt-get install locales -y
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
RUN echo 'LANG="en_US.UTF-8"' > /etc/default/locale
RUN dpkg-reconfigure --frontend=noninteractive locales
RUN update-locale en_US.UTF-8

# Install node, npm, and yarn.
ENV NODEREPO node_12.x
ENV DISTRO buster

RUN echo "deb https://deb.nodesource.com/${NODEREPO} ${DISTRO} main" > /etc/apt/sources.list.d/nodesource.list
ADD node.pub /tmp/node.pub
RUN cat /tmp/node.pub | apt-key add -

RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
ADD yarn.pub /tmp/yarn.pub
RUN cat /tmp/yarn.pub | apt-key add -

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main" > /etc/apt/sources.list.d/pgdg.list
ADD postgres.pub /tmp/postgres.pub
RUN cat /tmp/postgres.pub | apt-key add -
RUN echo "deb http://security.debian.org/debian-security buster/updates main " > /etc/apt/sources.list.d/debian-security.list

ADD chrome.pub /tmp/chrome.pub
RUN cat /tmp/chrome.pub | apt-key add -
RUN echo "deb https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list

# Update keys
RUN apt-key adv --refresh-keys --keyserver ha.pool.sks-keyservers.net
RUN apt-get update

# Install nodejs
RUN apt-get install nodejs yarn -y
RUN npm config set always-auth true

# Install postgres.
RUN apt-get install postgresql-10 -y

ENV PLV8_VERSION=v2.1.0 \
    PLV8_SHASUM="207d712e919ab666936f42b29ff3eae413736b70745f5bfeb2d0910f0c017a5c  v2.1.0.tar.gz"

RUN mkdir -p /tmp/build && cd /tmp/build \
  && apt-get install libncurses5 libc++-dev libc++abi-dev postgresql-server-dev-10 -y \
  && curl -LsSO https://github.com/plv8/plv8/archive/${PLV8_VERSION}.tar.gz \
  && tar -xvzf ${PLV8_VERSION}.tar.gz \
  && cd plv8-${PLV8_VERSION#?} \
  && make static \
  && make install \
  && strip /usr/lib/postgresql/10/lib/plv8.so \
  && cd \
  && rm -rf /tmp/build

# Install redis.
RUN apt-get install redis-server -y

# Install memcached.
RUN apt-get install memcached -y

# Ensure other circle/build requirements are installed and up to date.
RUN apt-get install git openssh-server libssl-dev tar gzip ca-certificates imagemagick jq cmake -y

# Install chrome/driver dependencies.
RUN apt-get install unzip libxi6 libgconf-2-4 libasound2 libatk1.0-0 libgtk-3-0 libnspr4 libxcomposite1 libxcursor1 libxrandr2 libxss1 libxtst6 fonts-liberation libappindicator1 libnss3 xdg-utils lsof -y

# Install Cypress dependencies.
RUN apt-get install libgtk2.0-0 libgbm-dev libnotify-dev xauth xvfb -y 

# Install Google Noto Color Emoji font for emoji support in PDFs
RUN mkdir -p /usr/share/fonts/truetype/noto && \
    curl -sSO https://noto-website-2.storage.googleapis.com/pkgs/NotoColorEmoji-unhinted.zip && \
    unzip -p NotoColorEmoji-unhinted.zip NotoColorEmoji.ttf > /usr/share/fonts/truetype/noto/NotoColorEmoji.ttf && \
    rm -rf NotoColorEmoji* && \
    fc-cache -f -v

# Install chrome.
RUN apt-get install google-chrome-stable -y

# Install chromedriver.
RUN curl -sSO https://chromedriver.storage.googleapis.com/2.41/chromedriver_linux64.zip
RUN sha256sum -c /chromedriver.sha256
RUN unzip chromedriver_linux64.zip
RUN rm chromedriver_linux64.zip
RUN mv -f chromedriver /usr/local/bin/chromedriver
RUN chown root:root /usr/local/bin/chromedriver
RUN chmod 0755 /usr/local/bin/chromedriver

# Clean up and free up space.
# RUN apt-get clean
# RUN apt-get autoremove --purge -y
RUN rm /chromedriver.sha256 /tmp/chrome.pub /tmp/node.pub /tmp/postgres.pub /tmp/yarn.pub

# Create circle user.
RUN adduser circleci --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
RUN usermod -aG sudo circleci

# Setup postgres.
RUN mkdir -p /usr/local/pgsql/data
RUN mkdir -p /usr/local/pgsql/log
RUN chown -Rf circleci /usr/local/pgsql/data
RUN chown -Rf circleci /usr/local/pgsql/log
RUN chown -Rf circleci /var/run/postgresql
RUN sudo -u circleci /usr/lib/postgresql/10/bin/initdb -D /usr/local/pgsql/data

# Set env.
ENV AHA_REDIS_URL redis://localhost:6379/0
ENV JEST_SUITE_NAME Aha! Tests
ENV JEST_JUNIT_OUTPUT "/tmp/jest/junit.xml"
ENV RAILS_ENV test
ENV LC_ALL "en_US.UTF-8"

# Add npmrc template.
RUN mkdir -p /usr/etc && echo '//registry.npmjs.org/:_authToken=${NPM_TOKEN}' > /usr/etc/npmrc

# Add start script.
ADD start.sh /root/start.sh

CMD /bin/bash
