require 'rake'

$LOAD_PATH.unshift File.expand_path("..", __FILE__)

require "relapse/version"
require "relapse/project"

module Relapse
  def windows?; RUBY_PLATFORM =~ /mingw|win32/; end
end