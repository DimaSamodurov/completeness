require "bundler/gem_tasks"
require "rake/testtask"
require "completeness"

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
end

task :default => :test