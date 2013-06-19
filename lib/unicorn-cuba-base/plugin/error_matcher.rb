module Plugin
  module ErrorMatcher
    def error(*klass)
      lambda {klass.any?{|k| env["app.error"].is_a? k} and captures.push(env["app.error"])}
    end

    def error?
      env.has_key? "app.error"
    end
  end
end

