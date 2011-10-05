class TestObserver
  def events
    @events ||= []
  end

  def notify(*args)
    events << args
  end
end
