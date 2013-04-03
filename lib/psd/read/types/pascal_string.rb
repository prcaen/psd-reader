module Psd
  module Read
    module Types
      class PascalString < BinData::Record
        uint8  :len
        string :data, :read_length => :len
      end
    end
  end
end
