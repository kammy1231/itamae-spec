require 'serverspec'
require 'net/ssh'
require 'specinfra/helper/set'
require 'json'
include Specinfra::Helper::Set

if ENV['LOCAL_MODE']
  set :backend, :exec
else
  set :backend, :ssh
end

 if ENV['ASK_SUDO_PASSWORD']
   begin
     require 'highline/import'
   rescue LoadError
     fail "highline is not available. Try installing it."
   end
   set :sudo_password, ask("Enter sudo password: ") { |q| q.echo = false }
 else
   set :sudo_password, ENV['SUDO_PASSWORD']
 end

host = ENV['TARGET_HOST']
node_file = ENV['NODE_FILE']
attributes = JSON.parse(File.read(node_file), symbolize_names: true)
set_property attributes

unless ENV['LOCAL_MODE']
  options = Net::SSH::Config.for(host)
  options[:user] = ENV['SSH_USER']
  options[:password] = ENV['SSH_PASSWORD']
  options[:keys] = ENV['SSH_KEY']
  options[:port] = ENV['SSH_PORT']

  set :host, options[:host_name] || host
  set :shell, '/bin/bash'
  set :ssh_options, options
end

set :request_pty, true
