def schedule_each(interval : Time::Span)
  loop {
    start = Pretty.now
    yield
    sleep [interval.seconds - (Pretty.now - start).milliseconds / 1000.0, 0].max
  }
end
