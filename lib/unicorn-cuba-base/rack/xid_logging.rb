module Rack
	class XIDLogging
		def initialize(app, root_logger, header_name = 'XID', &block)
			@root_logger = root_logger
			@header_name = header_name
			@app = app
		end

		def call(env)
			begin
				xid = env["HTTP_#{@header_name.upcase.tr('-', '_')}"]
				env['xid'] = {@header_name => xid}
				@root_logger.with_meta_context(xid: xid) do
					return @app.call(env)
				end
			ensure
			end
		end
	end
end
