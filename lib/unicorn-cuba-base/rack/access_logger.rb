module Rack
	class AccessLogger < Rack::CommonLogger
		def log(env, *args)
			# this is called after body was sent so it won't be in scope of XIDLogging - setting xid again
			xid = env['xid'] && env['xid'].first.last
			if xid
				@logger.with_meta_context(xid: xid) do
					super(env, *args)
				end
			else
				super(env, *args)
			end
		end
	end
end
