require 'logger'

class RootLogger < Logger
	class ClassLogger
		@@levels = [:debug, :info, :warn, :error, :fatal, :unknown]

		def initialize(root_logger, class_obj)
			@root_logger = root_logger
			@progname = class_obj.name
			@root_logger.formatter = proc do |severity, datetime, progname, msg|
				"[#{datetime.utc.strftime "%Y-%m-%d %H:%M:%S.%6N %Z"}] [#{$$} #{progname}] #{severity}: #{msg}\n"
			end
		end

		def respond_to?(method)
			@root_logger.respond_to? method
		end

		def method_missing(name, *args, &block)
			if @@levels.include? name
				message = if block_given?
					self.progname
				else
					args.map do |arg|
						if arg.is_a? Exception
							"#{arg.class.name}: #{arg.message}\n#{arg.backtrace.join("\n")}"
						else
							arg.to_s
						end
					end.join(': ')
				end

				# set program name to current class
				@root_logger.progname = @progname
				@root_logger.send(name, message, &block)
			else
				@root_logger.send(name, *args, &block)
			end
		end

		attr_reader :root_logger

		def inspect
			"#<ClassLogger[#{@progname}] #{"0x%X" % object_id} root_logger=#{@root_logger.inspect}>"
		end
	end

	def logger_for(class_obj)
		ClassLogger.new(self, class_obj)
	end

	def inspect
		"#<RootLogger #{"0x%X" % object_id}>"
	end
end

module ClassLogging
	module ClassMethods
		def init_logger
			@@logger = {} unless defined? @@logger
		end

		def logger=(logger)
			@@logger[self] = logger
		end

		def log
			unless @@logger[self]
				@@logger[self] = RootLogger::ClassLogger.new(Logger.new(STDERR), self)
				@@logger[self].warn "new default logger crated"
			end
			@@logger[self]
		end

		def logger_for(class_obj)
			RootLogger::ClassLogger.new(log.root_logger, class_obj)
		end
	end

	def log
		self.class.log
	end

	def logger_for(class_obj)
		self.class.logger_for(class_obj)
	end

	def self.included(class_obj)
		class_obj.extend ClassMethods
		class_obj.init_logger
	end
end

