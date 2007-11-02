# Extend Core Ruby Classes, i.e. String, Fixnum, Date, Time, etc.

module StringExtensions

  def trim_dot(chars = 30, dots = "...")
    new_str = self
    if self.size > chars
      new_str = self[0..chars] + dots
    end
    return new_str
  end
  
  def ensure_url
    without_http = self.gsub(/^http:\/\// , '')
    return "http://#{without_http}"
  end

  def strip_http
    return self.gsub(/^http:\/\// , '')
  end

  def strip_trailing_slash
    return self.gsub(/\/$/ , '')
  end

  def get_extension
    split_array = self.split('.')
    extension = split_array[split_array.size - 1]
    return extension
  end
  
  def strip_embed_tags
    txt = self
    txt = txt.gsub(/(<object).*(<\/object>)/, '')
    txt = txt.gsub(/(<embed).*(<\/embed>)/, '')
    return txt
  end
  
  def capitalize_each
    self.split(' ').each{|word| word.capitalize!}.join(' ')
  end
  
  def capitalize_each!
    replace capitalize_each
  end
  
  def auto_br
    return self.gsub(/\n/, '<br/>')
  end
  
  def make_plural(qty)
    ending = qty == 1 ? '' : 's'
    return "#{self}#{ending}"
  end
  
  def sanitize
    sanitized = ''
    if !self.nil?
     sanitized = self.gsub(/[\/~`!@#\$%\^&*()?><{};'"|\\,\[\]]/, '-')
    end
    return sanitized
  end
  
  def sanitize!
    replace sanitize
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
      guid = guid.first(MAX_GUID_LENGTH)

      # Now strip any excess underscores off the end
      guid = guid.gsub(/(_)+$/, '')
    end
    return guid
  end

  def guidify!
    replace guidify
  end
  
  def uri_escape
    escaped = URI.escape(self)
    escaped.gsub!('%20', '+')
    return escaped
  end
  
  def first_words(num_words)
    return '' if self.blank?
    words = self.split(' ')
    return words.slice(0, num_words).join(' ')
  end
  
  def munge
    self.gsub(',', '').to_i
  end

  def strip_to_double
    pct = self.dup
    pct.gsub!(',', '')
    pct.gsub!('%', '')
    return (pct.to_f * 0.01)
  end
  
end

module NumberExtensions

  # Formats the number in $XX.YY format, with an optional currency specifier.
  #   Usage: (5.6).dollar_format => "$5.60"
  def dollar_format(currency = '$')
    return "#{currency}%.2f" % self
  end

  # Formats a number with the number of decimal places provided.  Defaults to 2 if none provided.
  #   Usage: (3.14159).number_format => "3.14"
  def number_format(decimal_places = 2)
    return "%.#{decimal_places}f" % self
  end
  
  # Returns a comma-delimited (3 digits per comma) representation of the number.
  # Usage: 123456789.commify --> "123,456,789"
  def commify
    text = self.to_s.reverse
    text.gsub!(/(\d\d\d)(?=\d)(?!\d*\.)/, '\1,')
    return text.reverse
  end
  
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

class Fixnum
  include NumberExtensions
end

class Float
  include NumberExtensions
end

class Bignum
  include NumberExtensions
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
