#!/bin/bash
set -e

cd "$(dirname "$0")/.."

if [ -f .env ]; then
  set -a; source .env; set +a
fi

bundle exec ruby bot.rb
