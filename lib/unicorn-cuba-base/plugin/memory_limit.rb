module Plugin
	module MemoryLimit
		def memory_limit
			env["app.memory_limit"] or fail 'Rack::MemoryLimit middleware not used!'
		end
	end
end

