
def tz_offset(hour, offset)
  if offset > 14 or offset < -12
    raise "invalid offset"
  end  
  adjusted_time = hour - offset
  if adjusted_time > 23
    adjusted_time -= 24
  elsif adjusted_time < 0  
    adjusted_time += 24
  end  
  return adjusted_time
end

