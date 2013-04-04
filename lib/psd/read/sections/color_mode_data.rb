module Psd
  module Read
    module Sections
      class ColorModeData
        def initialize(stream, color_mode)
          Psd::LOG.info("### COLOR MODE DATA - pos: #{stream.pos} ###")
          @stream     = stream
          @color_mode = color_mode
        end

        def parse
          @length = BinData::Uint32be.read(@stream).value

          if @color_mode == Psd::COLOR_INDEXED || @color_mode == Psd::COLOR_DUOTONE
            Psd::LOG.warn("Not implemented for the moment")
            BinData::Skip.new(length: @length).read(@stream)
          else
            raise Psd::LengthException.new("Color mode data length error") unless @length == 0
          end
        end
      end
    end
  end
end
