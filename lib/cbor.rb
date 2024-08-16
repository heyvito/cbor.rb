# frozen_string_literal: true

require_relative "cbor/version"

class CBOR
  class Error < StandardError; end
  class InvalidCBORError < Error; end

  NULL = 0x00
  MAJOR_TYPE_MASK = 0x1F
  DECODERS = {
    0 => :decode_unsigned_int,
    1 => :decode_negative_int,
    2 => :decode_byte_string,
    3 => :decode_text_string,
    4 => :decode_array,
    5 => :decode_map,
    6 => :decode_tagged_value,
    7 => :decode_misc_value
  }.freeze

  def self.decode(data) = new(data).decode

  def self.decode2(data)
    inst = new(data)
    ret = inst.decode
    [ret, inst.cursor]
  end

  HEX_STRING = /^[a-fA-F0-9]*$/

  def initialize(data)
    @data = case data
    when String
      if HEX_STRING.match? data
        [data].pack("H*").unpack("C*")
      else
        data.unpack("C*")
      end
    when Array
      data
    end
    @cur = 0
    @len = @data.length
  end

  def cursor = @cur

  def decode
    decoder = DECODERS[peek_major_type]
    raise InvalidCBORError, "Invalid CBOR: Unknown major type #{peek_major_type}" if decoder.nil?

    send(decoder)
  end

  private

  def peek
    return NULL if @cur >= @len

    @data[@cur]
  end

  def advance
    return NULL if @cur >= @len

    @data[@cur].tap { @cur += 1 }
  end

  def take(n) = @data[@cur...@cur + n].tap { @cur += n }

  def peek_major_type = peek >> 5

  def decode_unsigned_int
    v = advance & MAJOR_TYPE_MASK
    return v if v < 24

    case v
    when 24
      advance
    when 25
      take(2).pack("C*").unpack1("S>")
    when 26
      take(4).pack("C*").unpack1("L>")
    when 27
      take(8).pack("C*").unpack1("Q>")
    else
      raise InvalidCBORError, "Invalid CBOR: Unknown unsigned int type #{v}"
    end
  end

  def decode_negative_int
    v = advance & MAJOR_TYPE_MASK
    return -1 - v if v < 24

    case v
    when 24
      -1 - advance
    when 25
      -1 - take(2).pack("C*").unpack1("S>")
    when 26
      -1 - take(4).pack("C*").unpack1("L>")
    when 27
      -1 - take(8).pack("C*").unpack1("Q>")
    else
      raise InvalidCBORError, "Invalid CBOR: Unknown unsigned int type #{v}"
    end
  end

  def decode_object_length
    len = advance & MAJOR_TYPE_MASK
    if len >= 24
      len = case len
      when 24
        advance
      when 25
        take(2).pack("C*").unpack1("S>")
      when 26
        take(4).pack("C*").unpack1("L>")
      when 27
        take(8).pack("C*").unpack1("Q>")
      else
        raise InvalidCBORError, "Invalid CBOR: Unknown unsigned int type for string length #{v}"
      end
    end

    len
  end

  def decode_byte_string
    len = decode_object_length
    take(len).pack("C*")
  end

  def decode_text_string = decode_byte_string

  def decode_array
    len = decode_object_length

    # TODO: Support float (tagged)
    len.times.to_a.map { decode }
  end

  def decode_map
    len = decode_object_length
    {}.tap do |r|
      len.times { r[decode] = decode }
    end
  end

  def decode_misc_value
    value = peek & MAJOR_TYPE_MASK
    if value <= 23
      case value
      when 20
        false
      when 21
        true
      when 22, 23
        nil
      end

    elsif value == 24
      advance

    else
      raise NotImplementedError, "Decoder for misc type #{value} is not implemented"
    end
  end
end
