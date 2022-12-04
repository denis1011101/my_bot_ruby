#!/bin/sh

hours_now=$(date "+%H")

hours_end='4'

while [ "$hours_now" != "$hours_end" ]; do ruby my_bot_ruby.rb; sleep 30m; done

