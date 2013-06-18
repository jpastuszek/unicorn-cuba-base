require_relative '../memory_limit'

module Rack
	class MemoryLimit
		def initialize(app, memory_limit)
			@app = app
			@memory_limit = memory_limit
		end

		def call(env)
			memory_limit = ::MemoryLimit.new(@memory_limit)
			env["app.memory_limit"] = memory_limit

			# use up limit when reading request data
			memory_limit.io env["rack.input"]
			return @app.call(env)
		end
	end
end

