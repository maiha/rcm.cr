macro param(name)
  env.params.url["{{name.id}}"]
end

macro ecr(name)
  render "#{__DIR__}/views/{{name.id}}.ecr"
end

macro ecr(name, layout)
  render "#{__DIR__}/views/{{name.id}}.ecr", "#{__DIR__}/views/{{layout.id}}.ecr"
end

macro body(value)
  body = {{value.id}}
  ecr "body", "layout"
end

macro route(path, action)
  {% for method in HTTP_METHODS %}
    {{method.id}} "{{path.id}}" do |env|
      {{action.id}}(env)
    end
  {% end %}
end
