# encoding: UTF-8

class MyHash
	def self.get_uint32(num)
		num - num / 0x100000000 * 0x100000000;
	end

	def self.hash(s)
		key = 5381
		s.split(//).each do |c|
			value = get_uint32(get_uint32(key << 5) + c.ord)
			key += value
			key = get_uint32 key
		end
		key & 0x7FFFFFFF
	end
end

if __FILE__ == $0
	p MyHash.hash("xxx_xxx_xxx_xxx")
end
