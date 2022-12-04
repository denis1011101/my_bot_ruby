#!/bin/bash

echo "start"

# su bot

killall -9 ruby my_bot_ruby.rb

export TOKEN=5433802293:AAEFGH67GVCC6u4uHly-cCNcdEZdXfbIRWA

rm Gemfile.lock

bundle install

# ruby my_bot_ruby.rb &!

echo "stop"

