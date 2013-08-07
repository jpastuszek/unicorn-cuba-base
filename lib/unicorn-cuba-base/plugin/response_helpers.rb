require 'securerandom'
require 'json'
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

		def write(code, content_type, body, headers = {})
			req.body.read # read all remaining upload before we send response so that client will read it
			res.status = code
			res["Content-Type"] = content_type
			headers.each do |key, value|
				res[key] = value
			end
			ResponseHelpers.stats.incr_total_write
			res.write body
		end

		def write_text(code, content_type, msg, headers = {})
			msg = msg.join("\r\n") if msg.is_a? Array
			write code, content_type, (msg.gsub(/(?<!\r)\n/, "\r\n") + "\r\n"), headers
		end

		def write_plain(code, msg, headers = {})
			write_text code, 'text/plain', msg, headers
		end

		def write_url_list(code, msg, headers = {})
			write_text code, 'text/uri-list', msg, headers
		end

		def write_error(code, error, headers = {})
			msg = error.message
			log.warn "sending #{code} error response: #{msg}"
			ResponseHelpers.stats.incr_total_write_error
			write_plain code, msg, headers
		end

		def write_json(code, obj, headers = {})
			write code, 'application/json', obj.to_json, headers
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

		def write_error_part(code, error, headers = {})
			msg = error.message
			log.warn "sending error in multipart response part: #{msg}"
			ResponseHelpers.stats.incr_total_write_error_part
			write_plain_part msg, headers.merge('Status' => code)
		end

		def write_epilogue
			res.write "--#{@boundary}--\r\n"
		end
	end
end

