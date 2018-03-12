
module Itamae
  module Logger
    class FileFormatter < Formatter
      def call(severity, datetime, progname, msg)
        log = "%s : %s" % ["%5s" % severity, msg2str(msg)]
        Time.now.strftime('%F %T %z').to_s + log + "\n"
      end
    end

    def self.broadcast(logger)
      Module.new do
        define_method(:add) do |*args, &block|
          logger.add(*args, &block)
          super(*args, &block)
        end

        define_method(:<<) do |x|
          logger << x
          super(x)
        end

        define_method(:close) do
          logger.close
          super()
        end

        define_method(:progname=) do |name|
          logger.progname = name
          super(name)
        end

        define_method(:formatter=) do |formatter|
          logger.formatter = formatter
          super(formatter)
        end

        define_method(:level=) do |level|
          logger.level = level
          super(level)
        end

        define_method(:local_level=) do |level|
          logger.local_level = level if logger.respond_to?(:local_level=)
          super(level) if respond_to?(:local_level=)
        end

        define_method(:silence) do |level = Logger::ERROR, &block|
          if logger.respond_to?(:silence)
            logger.silence(level) do
              if defined?(super)
                super(level, &block)
              else
                block.call(self)
              end
            end
          else
            if defined?(super)
              super(level, &block)
            else
              block.call(self)
            end
          end
        end
      end
    end
  end

  if Dir.exist?('logs')
    @file_logger = ::Logger.new('logs/itamae.log', 'daily').tap do |l|
      l.formatter = Itamae::Logger::FileFormatter.new
    end.extend(Itamae::Logger::Helper)

    @logger.extend Itamae::Logger.broadcast(@file_logger)
  end
end
