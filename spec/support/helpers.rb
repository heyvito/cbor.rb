# frozen_string_literal: true

module Helpers
  def decode(data) = CBOR.decode(data.gsub(/\n|\r|\t|\s/, ""))
end
