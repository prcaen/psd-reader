module Psd
  module Read
    class Tools
      def self.padding_2(i)
        (i + 1).floor / 2 * 2;
      end
    end
  end
end
