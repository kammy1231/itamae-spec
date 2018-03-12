# coding: utf-8
require "bundler/gem_tasks"
require 'rspec/core/rake_task'

require 'rake/extensiontask'
require 'rake/packagetask'
begin
  require 'bundler/gem_tasks'
rescue LoadError
  puts 'If you want to create gem, You must install Bundler'
end

require './lib/itamae-spec/version.rb'
def version
  ItamaeSpec::VERSION
end

Rake::ExtensionTask.new do |ext|
  ext.name = 'itamae-spec'
  ext.ext_dir = 'ext/'
  ext.lib_dir = 'lib/'
end

Rake::PackageTask.new('itamae-spec', "#{version}") do |t|
  t.need_tar_gz = true
  t.package_files.include `git ls-files`.split("\n")
end

namespace :release do
  desc "Bump up version and commit"
  task :version_up do
    version_file = File.expand_path("lib/itamae-spec/version.txt")
    current_version = File.read(version_file).strip

    if /\A(.+?)(\d+)\z/ =~ current_version
      next_version = "#{$1}#{$2.to_i + 1}"
    else
      raise "Invalid version"
    end

    open(version_file, "w") do |f|
      f.write next_version
    end
    system "git add #{version_file}"
    system "git commit -m 'Bump up version'"
  end
end
