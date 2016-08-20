require "redis"

module Redis::Codec
  module Text
    extend self

    def encode(value)
      case value
      when Nil
        "(nil)\n"
      when Redis::Error
        value.message + "\n"
      else
        value.inspect + "\n"
      end
    end
  end

  module Raw
    extend self

    def encode(value)
      case value
      when Nil
        ""
      when String, Int
        value.to_s
      when Array(String) # Array(RedisValue)
        value.map(&.to_s).join("\n")
      when Redis::Error
        value.message
      else
        "(#{value.class})#{value}"
      end
    end
  end

  module Resp
    extend self

    def encode(value)
      String.build do |io|
        marshal(value, io)
      end
    end

    # derived from https://github.com/stefanwille/crystal-redis/blob/master/src/redis/connection.cr

    def marshal(arg : Int, io)
      io << ":" << arg << "\r\n"
    end

    def marshal(arg : String, io)
      io << "$" << arg.bytesize << "\r\n" << arg << "\r\n"
    end

    def marshal(arg : Array(RedisValue), io)
      io << "*" << arg.size << "\r\n"
      arg.each do |element|
        marshal(element, io)
      end
    end

    def marshal(arg : Nil, io)
      io << "$-1\r\n"
    end

    def marshal(arg : Redis::Error, io)
      io << "-" << arg.to_s << "\r\n"
    end
  end
end
