def schedule_each(interval : Time::Span)
  loop {
    start = Time.now
    yield
    sleep [interval.seconds - (Time.now - start).milliseconds / 1000.0, 0].max
  }
end
