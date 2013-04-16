module Psd
  module Read
    module Sections
      class ColorModeData
        def initialize(stream, color_mode)
          @stream     = stream
          @color_mode = color_mode
          @length     = BinData::Uint32be.read(@stream).value
          @parsed     = false
        end

        def parse
          LOG.info("### COLOR MODE DATA ###")
          LOG.debug("Current position: #{Tools.format_size(@stream.pos)}")

          if @color_mode == COLOR_INDEXED || @color_mode == COLOR_DUOTONE
            LOG.warn("Not implemented for the moment")
            BinData::Skip.new(length: @length).read(@stream)
          else
            raise LengthException.new("Color mode data length error") unless @length == 0
          end

          parsed = true
        end

        def skip
          LOG.info("### COLOR MODE DATA - Skipped ###")
          BinData::Skip.new(length: @length).read(@stream)
        end

        def parsed?
          @parsed
        end
      end
    end
  end
end
