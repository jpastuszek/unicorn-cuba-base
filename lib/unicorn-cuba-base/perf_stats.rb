require 'benchmark'

$perf_stats_nest_level = -1

module PerfStats
	def measure(name)
		$perf_stats_nest_level += 1
		ret = nil
		took = Benchmark.measure do
			ret = yield
		end
		log.info "[PERF] #{took.to_s.chomp} -#{'+' * $perf_stats_nest_level} #{name}"
		ret
	ensure
		$perf_stats_nest_level -= 1
	end
end

