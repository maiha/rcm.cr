require "json"

module Rcm::Httpd::Formatable
  protected def format(cmd : RedisCommand::CommandFound, value)
    case cmd.mime
    when MediaType::Txt  then format_txt(value)
    when MediaType::Raw  then format_raw(value)
    when MediaType::Resp then format_resp(value)
    when MediaType::Json then format_json(value, cmd.name)
    end
  end

  protected def format(cmd : RedisCommand::Request)
    cmd.class.name.split(/::/).last
  end

  protected def format(err : Exception)
    err.message
  end

  private def format_txt(value)
    Redis::Codec::Text.encode(value)
  end

  private def format_raw(value)
    Redis::Codec::Raw.encode(value)
  end

  private def format_resp(value)
    Redis::Codec::Resp.encode(value)
  end

  private def format_json(value, name)
    {name.downcase => value}.to_json
  end
end
