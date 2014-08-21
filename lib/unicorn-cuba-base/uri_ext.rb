require 'uri'

module URI
	class << self
		alias_method :pct_decode, :decode
	end

	# From http://en.wikipedia.org/wiki/Percent-encoding:
	# The generic URI syntax mandates that new URI schemes that provide for the representation of character data in a URI must, in effect, represent characters from the unreserved set without translation, and should convert all other characters to bytes according to UTF-8, and then percent-encode those values.
	# Also sometimes JavaScript encode() function (deprecated) is being used; this uses %uXXXX encoding for UTF-8 chars
	def self.utf_decode(str)
		pct_decode(str) # decode %XX bits
		.force_encoding('UTF-8') # Make sure the string is interpreting UTF-8 chars
		.gsub(/%u([0-9a-z]{4})/) {|s| [$1.to_i(16)].pack("U")} # Decode %uXXXX encoded chars (JavaScript.encode())
		.tap do |u|
			# Validate fins string
			raise URI::InvalidURIError, "invalid UTF-8 encoding in URI: #{u.inspect}" if not u.valid_encoding?
		end
	end

	# Use it by default
	def self.decode(str)
		self.utf_decode(str)
	end
end
