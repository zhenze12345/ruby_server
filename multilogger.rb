# encoding: UTF-8

require 'logger'

class MultiLogger
	def format_logger(logger)
		logger.level = @level
		logger.formatter = proc do |severity, datetime, progname, msg|
			"[#{datetime.strftime("%Y-%m-%d %H:%M:%S.%3N")}] #{severity}: #{msg}\n"
		end	
	end

	def initialize(file, stdout = nil, level = Logger::DEBUG, count = 10, size = 10 * 1024 * 1024)
		@level = level
		if file
			@file_logger = Logger.new(file, count, size)
			format_logger(@file_logger)
		end
		if stdout
			@stdout_logger = Logger.new(STDOUT)
			format_logger(@stdout_logger)
		end
	end

	def close
		if @file_logger
			@file_logger.close
		end
		if @stdout_logger
			@stdout_logger.close
		end
	end

	def debug(progname = nil, &block)
		if @file_logger
			@file_logger.debug(progname, &block)
		end
		if @stdout_logger
			@stdout_logger.debug(progname, &block)
		end
	end

	def error(progname = nil, &block)
		if @file_logger
			@file_logger.error(progname, &block)
		end
		if @stdout_logger
			@stdout_logger.error(progname, &block)
		end
	end

	def fatal(progname = nil, &block)
		if @file_logger
			@file_logger.fatal(progname, &block)
		end
		if @stdout_logger
			@stdout_logger.fatal(progname, &block)
		end
	end

	def info(progname = nil, &block)
		if @file_logger
			@file_logger.info(progname, &block)
		end
		if @stdout_logger
			@stdout_logger.info(progname, &block)
		end
	end

	def warn(progname = nil, &block)
		if @file_logger
			@file_logger.warn(progname, &block)
		end
		if @stdout_logger
			@stdout_logger.warn(progname, &block)
		end
	end
end

if __FILE__ == $0
	logger = MultiLogger.new("hello.log", true)
	logger.debug "hello world"
	logger.info "hello world"
	logger.close
end
