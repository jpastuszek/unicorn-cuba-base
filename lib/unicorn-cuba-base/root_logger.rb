require 'logger'

class RootLogger < Logger
	class ClassLogger
		@@levels = [:debug, :info, :warn, :error, :fatal, :unknown]

		def initialize(root_logger, class_obj)
			@root_logger = root_logger
			@progname = class_obj.name
		end

		def respond_to?(method)
			super or @root_logger.respond_to? method
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
				@root_logger.send(name, message.chomp, &block)
			else
				@root_logger.send(name, *args, &block)
			end
		end

		attr_reader :root_logger

		def inspect
			"#<ClassLogger[#{@progname}] #{"0x%X" % object_id} root_logger=#{@root_logger.inspect}>"
		end
	end

	def initialize(logdev = STDERR, &formatter)
		super(logdev)

		# default formatter
		formatter ||= proc do |severity, datetime, progname, msg|
			"[#{datetime.utc.strftime "%Y-%m-%d %H:%M:%S.%6N %Z"}] [#{$$} #{progname}] #{severity}: #{msg}\n"
		end

		self.formatter = formatter
	end

	def logger_for(class_obj)
		ClassLogger.new(self, class_obj)
	end

	def root_logger
		self
	end

	def inspect
		"#<RootLogger #{"0x%X" % object_id}>"
	end
end

class SyslogLogDev
	def initialize(program_name, facility = 'daemon', log_to_stderr = false)
		require 'syslog'

		facility = "LOG_#{facility.upcase}".to_sym
		Syslog.constants.include? facility or fail "No such syslog facility: #{facility}"
		facility = Syslog.const_get facility

		@log_level_mapping = Hash[%w{DEBUG INFO WARN ERROR FATAL UNKNOWN}.zip(
			[Syslog::LOG_DEBUG, Syslog::LOG_INFO, Syslog::LOG_WARNING, Syslog::LOG_ERR, Syslog::LOG_CRIT, Syslog::LOG_NOTICE]
		)]
		@log_level_mapping.default = Syslog::LOG_NOTICE

		flags = Syslog::LOG_PID

		if log_to_stderr
			STDERR.sync = true
			flags |= Syslog::LOG_PERROR
			flags |= Syslog::LOG_ODELAY
		else
			flags |= Syslog::LOG_NDELAY
		end

		@syslog = Syslog.open(program_name, flags, facility)
	end

	def write(msg)
		log_level, msg = *msg.match(/([^ ]+) (.*)/m).captures
		msg.tr! "\n", "\t"
		@syslog.log(@log_level_mapping[log_level], msg)
	end

	def close
		@syslog.close
	end
end

class RootSyslogLogger < RootLogger
	def initialize(program_name, facility = 'daemon', log_to_stderr = false)
		super(SyslogLogDev.new(program_name, facility, log_to_stderr)) do |severity, datetime, progname, msg|
			# SyslogLogDev expects messages in format:
			"#{severity} #{progname}: #{msg}\n"
		end
	end

	# used when obj is used as log device (access logs)
	def write(msg)
		self << "UNKNOWN #{msg}"
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
				new_root_logger = false
				# use root logger from ancestor or create new one
				root_logger =
					if logging_class = ancestors.find{|an| an != self and an.respond_to? :log}
						logging_class.log.respond_to?(:root_logger) ? logging_class.log.root_logger : logging_class.log
					else
						new_root_logger = true
						Logger.new(STDERR)
					end

				root_logger.kind_of? RootLogger::ClassLogger and fail "got ClassLogger root logger: #{self}"

				logger = RootLogger::ClassLogger.new(root_logger, self)
				logger.warn "new default logger crated" if new_root_logger
				@@logger[self] = logger
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

