module Rack
	class XIDLogging
		def initialize(app, root_logger, header_name = 'XID', &block)
			@root_logger = root_logger
			@header_name = header_name
			@app = app
		end

		def call(env)
			begin
				@root_logger.with_meta_context(xid: env["HTTP_#{@header_name.upcase.tr('-', '_')}"]) do
					return @app.call(env)
				end
			ensure
			end
		end
	end
end
