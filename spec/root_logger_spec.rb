require_relative 'spec_helper'

require 'unicorn-cuba-base/root_logger'
require 'stringio'

describe RootLogger do
	let! :log_out do
		StringIO.new
	end

	subject do
		RootLogger.new(log_out)
	end

	it 'should log to given logger' do
		subject.info 'hello world'
		log_out.string.should include 'INFO'
		log_out.string.should include 'hello world'
	end

	describe 'support for different logging levels' do
		it 'should log info' do
			subject.info 'hello world'
			log_out.string.should include 'INFO'
		end

		it 'should log warn' do
			subject.warn 'hello world'
			log_out.string.should include 'WARN'
		end

		it 'should log error' do
			subject.error 'hello world'
			log_out.string.should include 'ERROR'
		end
	end

	describe 'class logger' do
		it 'should report class name' do
			TestApp = Class.new
			subject.logger_for(TestApp).info 'hello world'
			log_out.string.should include 'TestApp'

			subject.logger_for(String).info 'hello world'
			log_out.string.should include 'String'
		end
	end

	it 'should log exceptions' do
		begin
			raise RuntimeError, 'bad luck'
		rescue => error
			subject.logger_for(String).error 'hello world', error
		end
		log_out.string.should include 'hello world: RuntimeError: bad luck'
	end

	describe 'meta data' do
		it 'should log with metadata in RFC5424 format' do
			subject.with_meta(type: 'access-log').info 'GET /asdfas'
			log_out.string.should include '"type":"access-log"'

			subject.info 'GET /asdfas'
			log_out.string.lines.to_a.last.should_not include '"type":"access-log"'
		end

		it 'should work with chaining' do
			subject.with_meta(type: 'access-log').with_meta(blah: 'xxx').info 'GET /asdfas'
			log_out.string.should include '"type":"access-log","blah":"xxx"'
		end

		it 'should log with metadata context' do
			subject.with_meta_context(type: 'app-log') do
				subject.info 'GET /asdfas'
			end
			log_out.string.should include '"type":"app-log"'

			subject.info 'GET /asdfas'
			log_out.string.lines.to_a.last.should_not include '"type":"app-log"'
		end
	end
end

require 'capture-output'

describe SyslogLogDev do
	subject do
		SyslogLogDev.new('unicorn-cuba-base-test', 'daemon', true)
	end

	after :each do
		subject.close
	end

	it 'should write messages to syslog expecting first word to be log level' do
		Capture.stderr{subject.write 'INFO hello world'}.should include '<Info>'
		Capture.stderr{subject.write 'WARN hello world'}.should include '<Warning>'
		Capture.stderr{subject.write 'INFO hello world'}.should include 'hello world'
	end

	it 'should handle multiline log entries' do
		Capture.stderr{subject.write "INFO hello\nworld"}.should include "<Info>: hello\n\tworld\n"
	end
end

describe RootSyslogLogger do
	subject do
		@subject ||= RootSyslogLogger.new('unicorn-cuba-base-test', 'daemon', true).logger_for(RSpec)
	end

	after :each do
		subject.close
	end

	it 'should log to syslog' do
		log_out = Capture.stderr{subject.info 'hello world'}

		log_out.should include 'unicorn-cuba-base-test'
		log_out.should match /\[[0-9]+\]/
		log_out.should include '<Info>:'
	end

	it 'should include message' do
		Capture.stderr{subject.info 'hello world'}.should include 'hello world'
	end

	it 'should include class name' do
		Capture.stderr{subject.info 'hello world'}.should include 'RSpec'
	end

	it 'should map log levels to syslog severities' do
		Capture.stderr{subject.debug 'hello world'}.should include '<Debug>'
		Capture.stderr{subject.info 'hello world'}.should include '<Info>'
		Capture.stderr{subject.warn 'hello world'}.should include '<Warning>'
		Capture.stderr{subject.error 'hello world'}.should include '<Error>'
		Capture.stderr{subject.fatal 'hello world'}.should include '<Critical>'
	end

	it 'should handle multiline logs by appending tab after new line (done by syslog?)' do
		Capture.stderr{subject.info "hello\nworld\ntest"}.should include "hello\n\tworld\n\ttest\n"
	end

	describe 'direct wirtes' do
		it 'should use Info level' do
			Capture.stderr{subject.write "hello world"}.should include '<Info>'
		end

		it 'should allow use of meta data' do
			Capture.stderr{subject.with_meta('type' => 'access-log').write "hello world"}.should include '"type":"access-log"'
		end
	end
end
