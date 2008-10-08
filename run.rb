#!/usr/bin/env ruby

# This script lets you open up Ruby-Processing sketches
# without having to install JRuby.

# Stolen from ruby-processing and hacked around a bit

if file = "socialbeat.rb"
  mac=`which appletalk`
  ruby_processing_path = ENV["RUBY_PROCESSING_PATH"]
  jruby_path = File.join(ruby_processing_path, 'script/base_files/jruby-complete.jar') 
  if mac
    `java -cp #{jruby_path} -Xdock:name=Ruby-Processing -Xdock:icon=script/application_files/Contents/Resources/sketch.icns org.jruby.Main "#{file}"`
  else
    `java -cp #{jruby_path} org.jruby.Main "#{file}"`
  end
else
  puts "Couldn't find that sketch."
  puts "Usage: run.rb path/to/my_sketch.rb"
end
