require 'messagedecoder'
require 'myhash'

module ServerHandle
	@@server_array = []

	def self.get_server(num)
		@@server_array[num]
	end

	def get_msg_string(message)
		if message
			"[" + message.inspect.gsub("\n", " ").chop + "]"
		else
			""
		end
	end

	def post_init
		@data = ""
		@type = "unkown"
		@id = "unkown"
		array = get_peername[2,6].unpack "nC4"
		@address = array[1].to_s + "." + 
			array[2].to_s + "." + 
			array[3].to_s + "." + 
			array[4].to_s + ":" + 
			array[0].to_s
		$logger.info "server #{@address} connected"
	end

	def receive_data data
		@data += data
		$logger.debug "receive #{data.size} bytes from server #{@address} #{@type}:#{@id}"
		loop do
			length, msg_head, msg_body = $decoder.deserialize_server_msg(@data)
			# 如果解析消息出错
			if not length
				$logger.error "receive from server #{@address} #{@type}:#{@id} failed, close it"
				close_connection
				break
				#如果长度不够
			elsif length == 0
				break
			end
			# 如果解析出新消息
			@data = @data[length..@data.length]
			$logger.debug "receive from server #{@address} #{@type}:#{@id} msghead #{get_msg_string(msg_head)} msgbody #{get_msg_string(msg_body)}"

			case msg_head.MessageID
			when SERVER_MSG_ID::ID_S2S_REQUEST_REGISTER_SERVER.to_i
				on_register_server_request(msg_head, msg_body)
			else
				$logger.debug "invalid message id #{msg_head.MessageID} from server #{@address} #{@type}:#{@id}"
			end
		end
	end

	def transfer_msg(from_head, to_head)
		to_head.SrcFE = from_head.DstFE
		to_head.DstFE = from_head.SrcFE
		to_head.SrcID = from_head.DstID
		to_head.DstID = from_head.SrcID
	end

	def on_register_server_request(msg_head, msg_body)
		if msg_head.SrcFE != 2
			return
		end
		@type = "scene"
		@id = msg_head.SrcID
		@@server_array[@id] = [msg_body.IPAddress, msg_body.Port]
		head = CMessageHead.new
		transfer_msg(msg_head, head)
		head.MessageID = SERVER_MSG_ID::ID_S2S_RESPONSE_REGISTER_SERVER.to_i
		response = CMessageRegisterServerResponse.new
		send_message(head, response)
	end

	def send_message(msg_head, msg_body)
		buff = $decoder.serialize_server_msg(msg_head, msg_body)
		send_data buff
		$logger.debug "send to server #{@address} #{@type}:#{@id} msghead #{get_msg_string(msg_head)} msgbody #{get_msg_string(msg_body)}"
	end

	def unbind
		$logger.info "server #{@address} #{@type}:#{@id} close connection"
		@@server_array[@id] = nil
	end
end
