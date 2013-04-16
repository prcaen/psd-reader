module Psd
  module Read
    module Sections
      class ImageData
        def initialize(stream, color_mode)
          @stream     = stream
          @color_mode = color_mode
          @parsed     = false
        end

        def parse
          LOG.info("### IMAGE DATA ###")
          LOG.warn("not implemented")
        end
      end
    end
  end
end
