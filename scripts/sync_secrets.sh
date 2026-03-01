#!/bin/bash
set -e

cd "$(dirname "$0")/.."

git submodule update --remote data/secrets

echo "[$(date)] secrets synced"
