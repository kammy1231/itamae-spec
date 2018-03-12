
module Itamae
  module Generators
    class Cookbook
      def self.source_root
        File.expand_path('../templates/cookbook', __FILE__)
      end
    end
  end
end
