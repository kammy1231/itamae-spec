
module Itamae
  module Generators
    class Project
      def self.source_root
        File.dirname(__FILE__) + '/templates/project'
      end

      def bundle
        Dir.chdir(destination_root) do
          run 'bundle install'
        end
      end
    end
  end
end
