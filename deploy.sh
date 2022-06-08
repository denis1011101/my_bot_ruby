#!/bin/bash

echo "start"

# su bot

cd ~

killall -9 ruby my_bot_ruby.rb

rm -rf my_bot_ruby

git clone git@github.com:DenisDenis9331/my_bot_ruby.git

cd my_bot_ruby

rm Gemfile.lock

bundle install

ruby my_bot_ruby.rb &!

echo "stop"
