require 'itamae-spec'

module Itamae
  class CLI
    # Support for password authentication
    option :password, type: :string, desc: 'input ssh password'

    def initialize(*)
      super

      Itamae.logger.level = ::Logger.const_get(options[:log_level].upcase) if options[:log_level]
      Itamae.logger.formatter.colored = options[:color] if options[:color]
    end
  end
end
