require "itamae-spec/generators/project"
require "itamae-spec/generators/cookbook"

module Itamae
  module Generators
    def self.find(target)
      case target
      when 'cookbook'
        Cookbook
      when 'project'
        Project
      when 'role'
        puts 'Not support generate role. Do nothing.'
        exit 1
      else
        raise "Unexpected target: #{target}"
      end
    end
  end
end
