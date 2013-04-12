require 'myhash'
require 'messagedecoder'
require 'serverhandle'

module ClientHandle
	def get_msg_string(message)
		if message
			"[" + message.inspect.gsub("\n", " ").chop + "]"
		else
			""
		end
	end

	def post_init
		@data = ""
		array = get_peername[2,6].unpack "nC4"
		@address = array[1].to_s + "." + 
			array[2].to_s + "." + 
			array[3].to_s + "." + 
			array[4].to_s + ":" + 
			array[0].to_s
		$logger.info "client #{@address} connect to server"
	end

	def receive_data data
		@data += data
		$logger.debug "receive #{data.size} bytes from client #{@address}"
		loop do
			length, msg_head, msg_body = $decoder.deserialize_client_msg(@data)
			# 如果解析消息出错
			if not length
				$logger.error "receive from client #{@address} failed, close it"
				close_connection
				break
				#如果长度不够
			elsif length == 0
				break
			end
			# 如果解析出新消息
			@data = @data[length..@data.length]
			$logger.debug "receive from client #{@address} msghead #{get_msg_string(msg_head)} msgbody #{get_msg_string(msg_body)}"

			case msg_head.MessageID
			when CLIENT_MSG_ID::ID_C2S_REQUEST_LOGINLOGIC.to_i
				on_login_logic_request(msg_head, msg_body)
				true
			else
				$logger.debug "invalid message id #{msg_head.MessageID} from client #{@address}"
			end
		end
	end

	def on_login_logic_request(msg_head, msg_body)
		server_id = MyHash.hash(msg_body.Platform) % SERVER_COUNT + 1
		server = ServerHandle.get_server(server_id)
		if not server
			close_connection
			return
		end
		head = CMessageHead.new
		head.MessageID = CLIENT_MSG_ID::ID_S2C_RESPONSE_LOGINLOGIC.to_i
		response = CMessageLoginLogicResponse.new
		response.IPAddress = server[0]
		response.Port = server[1]
		send_message(head, response)
		close_connection_after_writing
	end

	def send_message(msg_head, msg_body)
		buff = $decoder.serialize_client_msg(msg_head, msg_body)
		send_data buff
		$logger.debug "send to client #{@address} msghead #{get_msg_string(msg_head)} msgbody #{get_msg_string(msg_body)}"
	end

	def unbind
		$logger.info "client #{@address} close connection"
	end
end
