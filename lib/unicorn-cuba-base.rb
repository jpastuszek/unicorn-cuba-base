require 'cli'
require 'cuba'
require 'unicorn'
require 'raindrops'
require 'facter'
require 'daemon'
require 'pathname'
require 'ip'

require_relative 'unicorn-cuba-base/stats'
require_relative 'unicorn-cuba-base/root_logger'
require_relative 'unicorn-cuba-base/plugin/error_matcher'
require_relative 'unicorn-cuba-base/plugin/logging'
require_relative 'unicorn-cuba-base/plugin/response_helpers'
require_relative 'unicorn-cuba-base/rack/error_handling'
require_relative 'unicorn-cuba-base/rack/unhandled_request'

class Controler < Cuba
	def self.root_logger=(root_logger)
		@@root_logger = root_logger
	end

	def self.logger_for(class_obj)
		@@root_logger.logger_for(class_obj)
	end
end

require_relative 'unicorn-cuba-base/stats_reporter'

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

	def initialize(program_name, defaults = {}, &block)
		instance_eval &block

		@cli = setup_cli(program_name, defaults, @cli_setup) or fail 'no cli defined'
		@settings = @settings_setup ? setup_settings(@settings_setup) : @cli.parse!

		root_logger = RootLogger.new(STDERR)
		root_logger.level = RootLogger::WARN
		root_logger.level = RootLogger::INFO if @settings.verbose
		root_logger.level = RootLogger::DEBUG if @settings.debug

		Daemon.daemonize(@settings.pid_file, @settings.log_file) unless @settings.foreground

		Controler.root_logger = root_logger

		Controler.settings[:listeners] = ["#{@settings.bind}:#{@settings.port}"]
		Controler.settings[:access_log_file] = @settings.access_log_file

		Controler.plugin Plugin::ErrorMatcher
		Controler.plugin Plugin::Logging
		Controler.plugin Plugin::ResponseHelpers

		@main_setup or fail 'no main controler provided'
		main_controler = setup_main(@main_setup) or fail 'no main controler class returned'

		access_log_file = @settings.access_log_file.open('a+')
		access_log_file.sync = true
		main_controler.use Rack::CommonLogger, access_log_file
		main_controler.use Rack::ErrorHandling
		main_controler.use Rack::UnhandledRequest

		unicorn_settings = {}
		unicorn_settings[:logger] = root_logger.logger_for(Unicorn::HttpServer)
		unicorn_settings[:worker_processes] = @settings.worker_processes
		unicorn_settings[:timeout] = @settings.worker_timeout
		unicorn_settings[:listeners] = ["#{@settings.bind}:#{@settings.port}"]
		unicorn_settings[:user] = @settings.user if @settings.user

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
			option :access_log_file,
				short: :a,
				cast: Pathname,
				description: 'NCSA access log file location',
				default: "#{program_name}_access.log"
			option :pid_file,
				short: :p,
				cast: Pathname,
				description: 'PID file location',
				default: "#{program_name}.pid"
			switch :foreground,
				short: :f,
				description: 'stay in foreground'
			option :bind,
				short: :b,
				cast: IP,
				description: 'HTTP server bind address - use 0.0.0.0 to bind to all interfaces',
				default: IP.new('127.0.0.1')
			option :port,
				short: :P,
				cast: Integer,
				description: 'HTTP server TCP listen port',
				default: defaults[:port] || 8080
			option :user,
				short: :u,
				description: 'run worker processes as given user'
			option :worker_processes,
				short: :w,
				cast: Integer,
				description: 'start given number of worker processes',
				default: Facter.processorcount.to_i + 1
			option :worker_timeout,
				short: :t,
				cast: Integer,
				description: 'workers handling the request taking longer than this time period will be forcibly killed',
				default: 60
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
