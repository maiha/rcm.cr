macro val(s)
  def {{s.target}}
    @{{s.target.stringify.gsub(/\?$/, "_p").id}} ||= ({{s.value}})
  end
end

macro var(name, default)
  def {{name.var.id}}
    if @{{name.var.id}}.nil?
      {{default}}
    else
      @{{name.var.id}}.not_nil!
    end
  end

  def {{name.var.id}}=(@{{name.var.id}} : {{name.type}})
  end
end

macro var(name)
  var({{name}}, {{name.type}}.new)
end
