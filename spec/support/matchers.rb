RSpec::Matchers.define :include_event do |type, object, data|
  match do |events|
    events.detect do |event|
      type == event.type && object == event.object && match_event_data(data, event.data)
    end
  end

  def match_event_data(expected, actual)
    expected.inject(true) do |result, (key, value)|
      result & case value
      when Regexp
        actual[key] =~ value
      else
        actual[key] == value
      end
    end
  end
end

