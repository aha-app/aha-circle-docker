FROM ruby:2.3

WORKDIR /

# Public key download locations
# chrome.pub    https://dl-ssl.google.com/linux/linux_signing_key.pub
# node.pub      https://deb.nodesource.com/gpgkey/nodesource.gpg.key
# postgres.pub  https://www.postgresql.org/media/keys/ACCC4CF8.asc
# yarn.pub      https://dl.yarnpkg.com/debian/pubkey.gpg

# Add SHA256 sum for ChromeDriver binary.
# Calculate with: curl -s DOWNLOAD_URL | shasum -a 256
# ChromeDriver  v2.33.506092  https://chromedriver.storage.googleapis.com/2.33/chromedriver_linux64.zip
ADD chromedriver.sha256 /chromedriver.sha256

# Install basic utilities for package installation and setup.
RUN apt-get update && apt-get upgrade -y
RUN apt-get install sudo apt-transport-https -y

# Set locale
RUN apt-get install locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
RUN echo 'LANG="en_US.UTF-8"' > /etc/default/locale
RUN dpkg-reconfigure --frontend=noninteractive locales
RUN update-locale en_US.UTF-8

# Install node, npm, and yarn.
ENV NODEREPO node_6.x
ENV DISTRO jessie

RUN echo "deb https://deb.nodesource.com/${NODEREPO} ${DISTRO} main" > /etc/apt/sources.list.d/nodesource.list
ADD node.pub /tmp/node.pub
RUN cat /tmp/node.pub | apt-key add -

RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
ADD yarn.pub /tmp/yarn.pub
RUN cat /tmp/yarn.pub | apt-key add -

RUN apt-get update
RUN apt-get install nodejs yarn -y

# Install postgres.
# The debian source is required since 9.5 is not provided by default on debian jessie.
# It can be removed when we upgrade to 9.6+.
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main" > /etc/apt/sources.list.d/pgdg.list
ADD postgres.pub /tmp/postgres.pub
RUN cat /tmp/postgres.pub | apt-key add -
RUN apt-get update
RUN apt-get install postgresql-9.5 -y

# Install redis.
RUN apt-get install redis-server -y

# Install memcached.
RUN apt-get install memcached -y

# Ensure other circle/build requirements are installed and up to date.
RUN apt-get install git openssh-server tar gzip ca-certificates imagemagick jq -y

# Install chrome/driver dependencies.
RUN apt-get install unzip xvfb libxi6 libgconf-2-4 libasound2 libatk1.0-0 libgtk-3-0 libnspr4 libxcomposite1 libxcursor1 libxrandr2 libxss1 libxtst6 fonts-liberation libappindicator1 libnss3 xdg-utils -y

# Install chrome.
ADD chrome.pub /tmp/chrome.pub
RUN cat /tmp/chrome.pub | apt-key add -
RUN echo "deb https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list
RUN apt-get update
RUN apt-get install google-chrome-stable

# Install chromedriver.
RUN curl -sSO https://chromedriver.storage.googleapis.com/2.33/chromedriver_linux64.zip
RUN sha256sum -c /chromedriver.sha256
RUN unzip chromedriver_linux64.zip
RUN rm chromedriver_linux64.zip
RUN mv -f chromedriver /usr/local/bin/chromedriver
RUN chown root:root /usr/local/bin/chromedriver
RUN chmod 0755 /usr/local/bin/chromedriver

# Clean up and free up space.
RUN apt-get clean
RUN apt-get autoremove --purge
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
RUN sudo -u circleci /usr/lib/postgresql/9.5/bin/initdb -D /usr/local/pgsql/data

# Set env.
ENV AHA_REDIS_URL redis://localhost:6379/0
ENV JEST_SUITE_NAME Aha! Tests
ENV JEST_JUNIT_OUTPUT "/tmp/jest/junit.xml"
ENV RAILS_ENV test
ENV LC_ALL "en_US.UTF-8"

# Add start script.
ADD start.sh /root/start.sh

# Add npmrc template.
RUN mkdir -p /usr/etc && echo '//registry.npmjs.org/:_authToken=${NPM_TOKEN}' > /usr/etc/npmrc

CMD /bin/bash
