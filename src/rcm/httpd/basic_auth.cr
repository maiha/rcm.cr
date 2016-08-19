require "http/server"
require "base64"

module Rcm::Httpd::BasicAuth
  protected def authorized?(ctx, username, password) : Bool
    return true if password.nil?

    username ||= "redis"
    if (header = ctx.request.headers["Authorization"]?)
      user, pass = Base64.decode_string(header[6..-1]).split(":", 2)
      return true if user.to_s == username.to_s && pass.to_s == password.to_s
    end

    headers = HTTP::Headers.new
    ctx.response.status_code = 401
    ctx.response.headers["WWW-Authenticate"] = %(Basic realm="Login Required")
    ctx.response.print "Authorization"
    return false
  end  
end
