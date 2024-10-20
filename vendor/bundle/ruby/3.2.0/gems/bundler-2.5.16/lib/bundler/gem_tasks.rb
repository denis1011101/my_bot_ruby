

require "rake/clean"
CLOBBER.include "pkg"

require_relative "gem_helper"
Bundler::GemHelper.install_tasks
