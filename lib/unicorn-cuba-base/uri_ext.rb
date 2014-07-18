require 'uri'

module URI
	class << self
		alias_method :pct_decode, :decode
	end

	# From http://en.wikipedia.org/wiki/Percent-encoding:
	# The generic URI syntax mandates that new URI schemes that provide for the representation of character data in a URI must, in effect, represent characters from the unreserved set without translation, and should convert all other characters to bytes according to UTF-8, and then percent-encode those values.
	def self.utf_decode(str)
		pct_decode(str).force_encoding('UTF-8').tap do |u|
			raise URI::InvalidURIError, "invalid UTF-8 encoding in URI: #{u.inspect}" if not u.valid_encoding?
		end
	end

	# Use it by default
	def self.decode(str)
		self.utf_decode(str)
	end
end
