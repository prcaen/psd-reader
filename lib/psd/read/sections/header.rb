module Psd
  module Read
    module Sections
      class Header
        attr_reader :channels, :color_mode, :depth, :height, :version, :width

        def initialize(stream)
          LOG.info("### HEADER ###")
          @stream = stream
        end

        def parse
          signature = BinData::String.new(read_length: LENGTH_SIGNATURE).read(@stream).value
          unless signature == SIGNATURE_PSD
            raise SignatureMismatch.new("PSD/PSB signature mismatch")
          end

          @version = BinData::Uint16be.read(@stream).value
          unless @version == VERSION_PSD || @version == VERSION_PSB
            raise VersionMismatch.new("PSD/PSB version mismatch")
          end

          reserved = BinData::Uint48be.read(@stream).value
          unless reserved == 0
            raise Exception.new("Reserved header must be 0")
          end

          @channels = BinData::Uint16be.read(@stream).value
          if channels < 1 || channels > 56
            raise ChannelsRangeOutOfBounds.new("Channels supported is 1 to 56, excpected: #{channels}")
          end

          @height = BinData::Uint32be.read(@stream).value
          @width  = BinData::Uint32be.read(@stream).value

          if version == VERSION_PSD
            if width < 1 || width > PIXELS_MAX_PSD || height < 1 || height > PIXELS_MAX_PSD
              raise SizeOutOfBounds.new("Out of bounds: width: #{width}px, height: #{height}px")
            end
          else
            if width < 1 || width > PIXELS_MAX_PSB || height < 1 || height > PIXELS_MAX_PSB
              raise SizeOutOfBounds.new("Out of bounds: width: #{width}px, height: #{height}px")
            end
          end

          @depth = BinData::Uint16be.read(@stream).value
          unless SUPPORTED_DEPTH.include? @depth
            raise DepthNotSupported("Depth #{@depth} is not supported.")
          end

          @color_mode = BinData::Uint16be.read(@stream).value
          unless COLOR_MODE.include? @color_mode
            raise ColorModeNotSupported("Color mode #{@color_mode} is not supported.")
          end
        end
      end
    end
  end
end
