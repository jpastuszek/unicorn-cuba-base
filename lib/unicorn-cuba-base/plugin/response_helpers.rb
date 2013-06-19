require 'securerandom'
require 'unicorn-cuba-base/stats'

module Plugin
	module ResponseHelpers
		extend Stats
		def_stats(
			:total_write_multipart,
			:total_write, 
			:total_write_part, 
			:total_write_error, 
			:total_write_error_part
		)

		def write(code, content_type, body)
			req.body.read # read all remaining upload before we send response so that client will read it
			res.status = code
			res["Content-Type"] = content_type
			ResponseHelpers.stats.incr_total_write
			res.write body
		end

		def write_plain(code, msg)
			msg = msg.join("\r\n") if msg.is_a? Array
			write code, 'text/plain', msg.gsub(/(?<!\r)\n/, "\r\n") + "\r\n"
		end

		def write_url_list(code, msg)
			msg = msg.join("\r\n") if msg.is_a? Array
			write code, 'text/uri-list', msg.gsub(/(?<!\r)\n/, "\r\n") + "\r\n"
		end

		def write_error(code, error)
			msg = error.message
			log.warn "sending #{code} error response: #{msg}"
			ResponseHelpers.stats.incr_total_write_error
			write_plain code, msg
		end

		def write_url_list(code, urls)
			write code, 'text/uri-list', urls.join("\r\n") + "\r\n"
		end

		# Multipart
		def write_preamble(code, headers = {})
			res.status = code
			@boundary = SecureRandom.uuid
			res["Content-Type"] = "multipart/mixed; boundary=\"#{@boundary}\""
			headers.each do |key, value|
				res[key] = value
			end
			ResponseHelpers.stats.incr_total_write_multipart
		end

		def write_part(content_type, body, headers = {})
			res.write "--#{@boundary}\r\n"
			res.write "Content-Type: #{content_type}\r\n"
			headers.each_pair do |name, value|
				res.write "#{name}: #{value}\r\n"
			end
			res.write "\r\n"
			ResponseHelpers.stats.incr_total_write_part
			res.write body
			res.write "\r\n"
		end

		def write_plain_part(msg, headers = {})
			write_part 'text/plain', msg.to_s.gsub("\n", "\r\n"), headers
		end

		def write_error_part(code, error)
			msg = error.message
			log.warn "sending error in multipart response part: #{msg}"
			ResponseHelpers.stats.incr_total_write_error_part
			write_plain_part msg, 'Status' => code
		end

		def write_epilogue
			res.write "--#{@boundary}--\r\n"
		end
	end
end

