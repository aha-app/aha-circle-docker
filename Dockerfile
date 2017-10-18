FROM ruby:2.3

WORKDIR /

# Install basic utilities for package installation and setup.
RUN apt-get update
RUN apt-get install sudo apt-transport-https -y

# Install node, npm, and yarn.
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update
RUN apt-get install nodejs yarn -y

# Install postgres.
# The debian source is required since 9.5 is not provided by default on debian jesse.
# It can be removed when we upgrade to 9.6+.
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get update
RUN apt-get install postgresql-9.5 -y

# Install redis.
RUN apt-get install redis-server -y

# Install memcached.
RUN apt-get install memcached -y

# Ensure other circle/build requirements are installed and up to date.
RUN apt-get install git openssh-server tar gzip ca-certificates imagemagick -y

# Install chrome/driver dependencies.
RUN apt-get install unzip xvfb libxi6 libgconf-2-4 libasound2 libatk1.0-0 libgtk-3-0 libnspr4 libxcomposite1 libxcursor1 libxrandr2 libxss1 libxtst6 fonts-liberation libappindicator1 libnss3 xdg-utils -y

# Install chrome.
RUN wget --quiet -N https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -P ~/
RUN dpkg -i ~/google-chrome-stable_current_amd64.deb

# Install chromedriver.
RUN wget --quiet -N http://chromedriver.storage.googleapis.com/$(curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE)/chromedriver_linux64.zip -P ~/
RUN unzip ~/chromedriver_linux64.zip -d ~/
RUN rm ~/chromedriver_linux64.zip
RUN mv -f ~/chromedriver /usr/local/bin/chromedriver
RUN chown root:root /usr/local/bin/chromedriver
RUN chmod 0755 /usr/local/bin/chromedriver

# Clean up and free up space.
RUN apt-get clean
RUN apt-get autoremove --purge

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

# Install bundler.
ENV BUNDLER_VERSION 1.15.1
RUN gem install bundler --version "$BUNDLER_VERSION"

# Install gems globally.
ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME"
ENV BUNDLE_BIN="$GEM_HOME/bin"
ENV BUNDLE_SILENCE_ROOT_WARNING=1
ENV BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $BUNDLE_BIN:$PATH
RUN mkdir -p "$GEM_HOME" "$BUNDLE_BIN"
RUN chmod 777 "$GEM_HOME" "$BUNDLE_BIN"

# Install patched phantomjs.
RUN gem install specific_install
RUN gem specific_install https://github.com/aha-app/phantomjs-gem.git
ADD phantomjs.rb /root/phantomjs.rb
RUN ruby /root/phantomjs.rb

# Set env.
ENV AHA_REDIS_URL redis://localhost:6379/0
ENV JEST_SUITE_NAME Aha! Tests
ENV JEST_JUNIT_OUTPUT "/tmp/jest/junit.xml"
ENV RAILS_ENV test

# Add start script.
ADD start.sh /root/start.sh

CMD /bin/sh
