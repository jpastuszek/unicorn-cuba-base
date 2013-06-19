require 'raindrops'

module Stats
	class MyStruct < Raindrops::Struct
		def self.new(*members)
			klass = super(*members)

			str = ''
			# add support to increment by more than 1
			members.map { |x| x.to_sym }.each_with_index do |member, i|
				str << "def incr_#{member}(v = 1); @raindrops.incr(#{i}, v); end; "
				str << "def decr_#{member}(v = 1); @raindrops.decr(#{i}, v); end; "
			end

			klass.class_eval(str)
			klass
		end
	end

	def def_stats(*stat_names)
		@@local_stats ||= {}
		stats_class = eval "MyStruct.new(#{stat_names.map{|s| ":#{s.to_s}"}.join(', ')})"
		@@local_stats[self] = stats_class.new
	end

	def stats
		@@local_stats[self]
	end
end

