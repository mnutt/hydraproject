module StringExtensions
  
  def escape_xml
    tmp = self.dup
    tmp.gsub!('&', '&amp;')
    tmp.gsub!('<', '&lt;')
    tmp.gsub!('>', '&gt;')
    return tmp
  end
  
  def unescape_xml
    tmp = self.dup
    tmp.gsub!('&lt;', '<')
    tmp.gsub!('&gt;', '>')
    tmp.gsub!('&amp;', '&')
    return tmp
  end
  
  def guidify
    guid = self
    if !guid.nil?
      # First take out the Special Characters
      guid = guid.gsub(/[^A-Za-z0-9\s]/, '')
      # Next make the whitespace into underscores
      guid = guid.gsub(/[\s\t\r\n\f]/, '_')
      # Now make double-underscores (in case we have any) into single ones
      guid = guid.gsub(/__/, '_')
    
      # Now make sure it's a reasonable length
      guid = guid.first(40)

      # Now strip any excess underscores off the end
      guid = guid.gsub(/(_)+$/, '')
    end
    return guid
  end
  
end

module NumberExtensions

  def to_ordinal
    num = self.to_i
    if (10...20)===num
      "#{num}th"
    else
      g = %w{ th st nd rd th th th th th th }
      a = num.to_s
      c=a[-1..-1].to_i
      a + g[c]
    end
  end
  
end

# Date and time extensions to extend the core Ruby Date and Time classes.

module TimeExtensions

  # Returns a Date object
  def to_date
    return Date.new(self.year, self.month, self.mday)
  end

  def nice_print
    return self.strftime("%b %d, %Y")
  end

  # Prints the date like:  Monday, June 10th of 2006.
  def full_print
    day_ordinal = self.day.to_ordinal
    return self.strftime("%A, %B #{day_ordinal} of %Y")
  end
  
end

module DateExtensions

  def to_time
    return Time.gm(self.year, self.month, self.mday)
  end

  def nice_print
    return self.strftime("%b %d, %Y")
  end

end

module ArrayExtensions

  def randomize
    self.sort_by { rand }
  end

  def randomize!
    replace randomize
  end

end

class String
  include StringExtensions
end

class Time
  include TimeExtensions
end

class Date
  include DateExtensions
end

class Array
  include ArrayExtensions
end

