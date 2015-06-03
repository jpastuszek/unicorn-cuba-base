require 'benchmark'

$perf_stats_nest_level = -1
$perf_stats_tasks = []

module PerfStats
	def measure(task, object = nil)
		$perf_stats_nest_level += 1
		$perf_stats_tasks << task
		task = $perf_stats_tasks.join(' -> ')
		ret = nil
		took = Benchmark.measure do
			ret = yield
		end
		log.with_meta(
			className: "PerfStats",
			user_time: took.utime.round(6),
			system_time:took.stime.round(6),
			total_time: took.total.round(6),
			real_time: took.real.round(6),
			task: task,
			object: object,
			level: $perf_stats_nest_level
		).info "took #{"%0.6f" % took.real} sec - #{task}#{object ? ": #{object}" : ''}"
		ret
	ensure
		$perf_stats_nest_level -= 1
		$perf_stats_tasks.pop
	end
end

