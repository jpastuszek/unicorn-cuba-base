require 'benchmark'

$perf_stats_nest_level = -1

module PerfStats
	def measure(name)
		$perf_stats_nest_level += 1
		ret = nil
		took = Benchmark.measure do
			ret = yield
		end
		log.with_meta(
			className: "PerfStats",
			user: took.utime.round(6),
			system:took.stime.round(6),
			total: took.total.round(6),
			real: took.real.round(6),
			task: name,
			level: $perf_stats_nest_level
		).info "[PERF] #{"%0.6f" % took.real} sec -#{'+' * $perf_stats_nest_level} #{name} "
		ret
	ensure
		$perf_stats_nest_level -= 1
	end
end

