FROM ruby:2.3-alpine

WORKDIR /

# Install node/npm.
RUN apk --update --no-cache add "nodejs<7"

# Install sudo.
RUN apk --no-cache add sudo

# Update npm and install yarn.
RUN sudo npm install -g npm --prefix=/usr/local
RUN sudo npm install -g yarn

# Install postgres.
RUN apk --no-cache add "postgresql<9.6" "postgresql-contrib<9.6" postgresql-dev

# Install redis.
RUN apk --no-cache add redis

# Install memcached.
RUN apk --no-cache add memcached

# Install other circle and build requirements.
RUN apk --no-cache add alpine-sdk linux-headers git openssh tar gzip ca-certificates qt5-qtwebkit-dev imagemagick
ENV QMAKE /usr/lib/qt5/bin/qmake

# Create circle user.
RUN adduser -S circleci

# Setup postgres.
RUN mkdir -p /usr/local/pgsql
RUN chown -Rf circleci /usr/local/pgsql

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
