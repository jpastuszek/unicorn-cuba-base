require 'cli'
require 'cuba'
require 'unicorn'
require 'unicorn/launcher'
require 'facter'
require 'pathname'
require 'ip'

require_relative 'unicorn-cuba-base/uri_ext'
require_relative 'unicorn-cuba-base/stats'
require_relative 'unicorn-cuba-base/root_logger'
require_relative 'unicorn-cuba-base/plugin/error_matcher'
require_relative 'unicorn-cuba-base/plugin/logging'
require_relative 'unicorn-cuba-base/plugin/response_helpers'
require_relative 'unicorn-cuba-base/plugin/memory_limit'
require_relative 'unicorn-cuba-base/rack/error_handling'
require_relative 'unicorn-cuba-base/rack/unhandled_request'
require_relative 'unicorn-cuba-base/rack/memory_limit'
require_relative 'unicorn-cuba-base/rack/xid_logging'

class Controler < Cuba
	include ClassLogging
end

require_relative 'unicorn-cuba-base/stats_reporter'
require_relative 'unicorn-cuba-base/default_error_reporter'

class Application
	def cli(&block)
		@cli_setup = block
	end

	def settings(&block)
		@settings_setup = block
	end

	def main(&block)
		@main_setup = block
	end

	def after_fork(&block)
		@after_fork = block
	end

	def initialize(program_name, defaults = {}, &block)
		instance_eval &block

		@cli = setup_cli(program_name, defaults, @cli_setup) or fail 'no cli defined'
		@settings = @settings_setup ? setup_settings(@settings_setup) : @cli.parse!

		root_logger = if @settings.syslog_facility
			# open /dev/null as log file if we are using syslog and we are not in foreground
			@settings.log_file = Pathname.new '/dev/null' unless @settings.foreground
			RootSyslogLogger.new(program_name, @settings.syslog_facility, @settings.foreground)
		else
			RootLogger.new
		end

		root_logger.level = RootLogger::WARN
		root_logger.level = RootLogger::INFO if @settings.verbose
		root_logger.level = RootLogger::DEBUG if @settings.debug
		Controler.logger = root_logger
		MemoryLimit.logger = Controler.logger_for(MemoryLimit)

		unicorn_settings = {}
		unicorn_settings[:logger] = root_logger.logger_for(Unicorn::HttpServer)
		unicorn_settings[:pid] = @settings.pid_file.to_s
		unicorn_settings[:worker_processes] = @settings.worker_processes
		unicorn_settings[:timeout] = @settings.worker_timeout
		unicorn_settings[:listeners] = @settings.listener
		unicorn_settings[:user] = @settings.user if @settings.user
		unicorn_settings[:rewindable_input] = false # don't keep the upload data in memory or on disk (tmp)
		unicorn_settings[:after_fork] = @after_fork if @after_fork

		unless @settings.foreground
			unicorn_settings[:stderr_path] = @settings.log_file.to_s
			unicorn_settings[:stdout_path] = @settings.log_file.to_s

			Unicorn::Launcher.daemonize!(unicorn_settings)

			# capture startup messages
			@settings.log_file.open('ab') do |log|
				log.sync = true
				STDERR.reopen log
				STDOUT.reopen log
			end
		end

		Controler.settings[:listeners] = @settings.listener
		#Controler.settings[:access_log_file] = @settings.access_log_file

		Controler.plugin Plugin::ErrorMatcher
		Controler.plugin Plugin::Logging
		Controler.plugin Plugin::ResponseHelpers
		Controler.plugin Plugin::MemoryLimit

		@main_setup or fail 'no main controller provided'
		main_controler = setup_main(@main_setup) or fail 'no main controler class returned'

		main_controler.use Rack::XIDLogging, root_logger, @settings.xid_header if @settings.xid_header

		if @settings.syslog_facility
			main_controler.use Rack::CommonLogger, root_logger.with_meta(type: 'access-log')
		else
			access_log_file = @settings.access_log_file.open('a+')
			access_log_file.sync = true
			main_controler.use Rack::CommonLogger, access_log_file
		end

		main_controler.use Rack::MemoryLimit, @settings.limit_memory * 1024 ** 2
		main_controler.use Rack::ErrorHandling
		main_controler.use Rack::UnhandledRequest

		Unicorn::HttpServer.new(main_controler, unicorn_settings).start.join
	end

	private

	def setup_cli(program_name, defaults, block)
		CLI.new do
			instance_eval &block
			option :log_file,
				short: :l,
				cast: Pathname,
				description: 'log file location',
				default: "#{program_name}.log"
			option :syslog_facility,
				short: :s,
				description: 'when set logs will be sent to syslog instead of log files; one of: auth, authpriv, cron, daemon, ftp, kern, lpr, mail, news, syslog, user, uucp, local0, local1, local2, local3, local4, local5, local6, local7'
			option :access_log_file,
				short: :a,
				cast: Pathname,
				description: 'NCSA access log file location',
				default: "#{program_name}_access.log"
			option :xid_header,
				short: :x,
				description: 'log value of named request header with request context'
			option :pid_file,
				short: :p,
				cast: Pathname,
				description: 'PID file location',
				default: "#{program_name}.pid"
			switch :foreground,
				short: :f,
				description: 'stay in foreground'
			options :listener,
				short: :L,
				description: 'HTTP server listener (bind) address in format <ip>:<port> or unix:<file> or ~[<username>]/<file> for UNIX sockets',
				default: '127.0.0.1:' + (defaults[:port] || 8080).to_s
			option :user,
				short: :u,
				description: 'run worker processes as given user'
			option :worker_processes,
				short: :w,
				cast: Integer,
				description: 'start given number of worker processes',
				default: (Facter.processorcount.to_i + 1) * (defaults[:processor_count_factor] || 1)
			option :worker_timeout,
				short: :t,
				cast: Integer,
				description: 'workers handling the request taking longer than this time period will be forcibly killed',
				default: 300
			option :limit_memory,
				cast: Integer,
				description: 'memory usage limit in MiB',
				default: 128
			switch :verbose,
				short: :v,
				description: 'enable verbose logging (INFO)'
			switch :debug,
				short: :d,
				description: 'enable verbose and debug logging (DEBUG)'
		end
	end

	def setup_settings(block)
		@cli.parse!(&block)
	end

	def setup_main(block)
		block.call @settings
	end
end

