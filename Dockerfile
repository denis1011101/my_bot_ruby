# Dockerfile
FROM ruby:3.4.6-alpine

RUN apk add --no-cache \
    bash \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ttf-freefont \
    ca-certificates \
    git \
    build-base \
    libxml2-dev \
    libxslt-dev \
    pkgconfig \
    tzdata \
    libffi-dev \
    musl-dev \
    yaml-dev

RUN git config --global --add safe.directory '*'

# Предустановка nokogiri для Alpine
RUN gem install nokogiri --platform=x86_64-linux-musl

ENV BROWSER_PATH=/usr/bin/chromium-browser
WORKDIR /work