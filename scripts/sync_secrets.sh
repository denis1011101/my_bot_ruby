#!/bin/bash
set -e

cd "$(dirname "$0")/.."

cd data/secrets && git checkout -- . && cd ../..
git submodule update --remote data/secrets

echo "[$(date)] secrets synced"
