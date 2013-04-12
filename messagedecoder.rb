require 'message.pb'
require 'clientmessage.pb'
require 'servermessage.pb'
require 'socket'
require 'zlib'

class MessageDecoder

	# 消息解析哈希表
	@@msg_hash = {
		CLIENT_MSG_ID::ID_C2S_REQUEST_LOGINLOGIC.to_i => CMessageLoginLogicRequest,
		SERVER_MSG_ID::ID_S2S_REQUEST_REGISTER_SERVER.to_i => CMessageRegisterServerRequest,
		SERVER_MSG_ID::ID_S2S_RESPONSE_REGISTER_SERVER.to_i => CMessageRegisterServerResponse,
	}

	# 接收时需要解压缩的消息
	@@compress_array = [
	]

	# 序列化服务器消息
	def serialize_server_msg(msghead, msgbody)
		msg_head_buf = msghead.serialize_to_string
		msg_body_buf = msgbody.serialize_to_string
		len = 2 + msg_head_buf.size + 4 + msg_body_buf.size
		[len].pack('L<') +
			[msg_head_buf.size].pack('S<') +
			msg_head_buf +
			[msg_body_buf.size].pack('L<') +
			msg_body_buf
	end

	# 序列化客户端消息
	def serialize_client_msg(msghead, msgbody)
		msg_head_buf = msghead.serialize_to_string
		msg_body_buf = msgbody.serialize_to_string
		len = 4 + 2 + msg_head_buf.size + 4 + msg_body_buf.size
		[len].pack('L<') +
			[0].pack('L<') +
			[msg_head_buf.size].pack('S<') +
			msg_head_buf +
			[msg_body_buf.size].pack('L<') +
			msg_body_buf
	end

	# 反序列化服务器消息
	def deserialize_server_msg(buff)
		if buff.size < 4
			return [0, nil, nil]
		end
		tmp_buff = buff[0,4]
		total_len = tmp_buff.unpack('L<')[0]
		position = 4
		if total_len + 4 > buff.size
			return [0, nil, nil]
		end

		if total_len <= 6 or total_len > 100000
			return [nil, nil, nil]
		end

		tmp_buff = buff[position, 2]
		msg_head_len = tmp_buff.unpack('S<')[0]
		position += 2
		tmp_buff = buff[position, msg_head_len]
		msg_head = CMessageHead.new
		msg_head.parse_from_string(tmp_buff)
		position += msg_head_len
		tmp_buff = buff[position, 4]
		msg_body_len = tmp_buff.unpack('L<')[0]
		position += 4
		tmp_buff = buff[position, msg_body_len]
		# 解压
		if @@compress_array.include? msg_head.MessageID
			tmp_buff = Zlib::Inflate.inflate tmp_buff
			if not tmp_buff
				return [nil, nil, nil]
			end
		end
		msg_body = @@msg_hash[msg_head.MessageID].new
		if msg_body
			msg_body.parse_from_string tmp_buff
		end
		[total_len + 4, msg_head, msg_body]
	end

	# 反序列化客户端消息
	def deserialize_client_msg(buff)
		if buff.size < 4
			return [0, nil, nil]
		end
		tmp_buff = buff[0,4]
		total_len = tmp_buff.unpack('L<')[0]
		position = 8
		if total_len + 4 > buff.size
			return [0, nil, nil]
		end

		if total_len <= 6 or total_len > 100000
			return [nil, nil, nil]
		end

		tmp_buff = buff[position, 2]
		msg_head_len = tmp_buff.unpack('S<')[0]
		position += 2
		tmp_buff = buff[position, msg_head_len]
		msg_head = CMessageHead.new
		msg_head.parse_from_string(tmp_buff)
		position += msg_head_len
		tmp_buff = buff[position, 4]
		msg_body_len = tmp_buff.unpack('L<')[0]
		position += 4
		tmp_buff = buff[position, msg_body_len]
		# 解压
		if @@compress_array.include? msg_head.MessageID
			tmp_buff = Zlib::Inflate.inflate tmp_buff
			if not tmp_buff
				return [nil, nil, nil]
			end
		end
		msg_body = @@msg_hash[msg_head.MessageID].new
		if msg_body
			msg_body.parse_from_string tmp_buff
		end
		[total_len + 4, msg_head, msg_body]
	end
end
