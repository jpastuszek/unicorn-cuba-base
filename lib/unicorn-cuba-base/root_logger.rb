require 'logger'

class RootLogger < Logger
	class ClassLogger
		@@levels = [:debug, :info, :warn, :error, :fatal, :unknown]

		def initialize(root_logger, class_obj)
			@root_logger = root_logger
			@class_name = class_obj.name
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

				# log with class name
				@root_logger.with_meta('className' => @class_name).send(name, message.chomp, &block)
			else
				# forward to root logger
				@root_logger.send(name, *args, &block)
			end
		end

		attr_reader :root_logger

		def inspect
			"#<ClassLogger[#{@progname}] #{"0x%X" % object_id} root_logger=#{@root_logger.inspect}>"
		end
	end

	class MetaData < Hash
		def to_s
			"[meta #{map{|k, v| "#{k}=\"#{v.to_s.tr('"', "'")}\""}.join(' ')}]"
		end
	end

	def initialize(logdev = STDERR, &formatter)
		super(logdev)

		@ext_formatter = proc do |severity, datetime, progname, meta, msg|
			if formatter
				formatter.call(severity, datetime, progname, meta, msg)
			else
				"#{datetime.utc.strftime "%Y-%m-%d %H:%M:%S.%6N %Z"} #{meta.to_s} #{severity}: #{msg}\n"
			end
		end

		@meta = MetaData.new
		@meta['pid'] = $$

		self.formatter = proc do |severity, datetime, progname, msg|
			@ext_formatter.call(severity, datetime, progname, @meta, msg)
		end
	end

	def logger_for(class_obj)
		ClassLogger.new(self, class_obj)
	end

	def root_logger
		self
	end

	attr_accessor :meta

	def with_meta(hash)
		n = self.dup
		n.meta = @meta.merge hash

		# capture new meta hash with this new formatter proc - needed since old formatter proc will point to old object
		n.formatter = proc do |severity, datetime, progname, msg|
			@ext_formatter.call(severity, datetime, progname, n.meta, msg)
		end
		n
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

		@log_level_mapping = Hash[%w{DEBUG INFO WARN ERROR FATAL}.zip(
			[Syslog::LOG_DEBUG, Syslog::LOG_INFO, Syslog::LOG_WARNING, Syslog::LOG_ERR, Syslog::LOG_CRIT]
		)]
		@log_level_mapping.default = Syslog::LOG_NOTICE

		flags = Syslog::LOG_PID | Syslog::LOG_NDELAY

		if log_to_stderr
			STDERR.sync = true
			flags |= Syslog::LOG_PERROR
		end

		@syslog = Syslog.open(program_name, flags, facility)
	end

	def write(msg)
		log_level, msg = *msg.match(/([^ ]+) (.*)/m).captures
		@syslog.log(@log_level_mapping[log_level], "%s", msg)
	end

	def close
		@syslog.close
	end
end

class RootSyslogLogger < RootLogger
	def initialize(program_name, facility = 'daemon', log_to_stderr = false)
		super(SyslogLogDev.new(program_name, facility, log_to_stderr)) do |severity, datetime, progname, meta, msg|
			# provide severity to SyslogLogDev
			"#{severity} #{meta} #{msg}\n"
		end

		@meta.delete 'pid' # pid is already within syslog message header
	end

	# used when obj is used as log device (access logs)
	def write(msg)
		info(msg)
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
			unless @@logger.include? self
				root_logger = if an = ancestors.find{|an| an != self and an.respond_to? :log and an.log.respond_to? :root_logger}
					an.log.root_logger
				else
					logger.warn 'no root logger found; using default logger'
					Logger.new(STDERR)
				end

				@@logger[self] = RootLogger::ClassLogger.new(root_logger, self)
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

