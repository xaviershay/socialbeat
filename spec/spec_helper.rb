require 'rubygems'
require 'spec'

alias :L :lambda

def F(path)
  File.expand_path(File.join(File.dirname(__FILE__), path))
end

$LOAD_PATH.unshift(F('../lib'))
require 'rubygems'
require F('support/executed_counter')
