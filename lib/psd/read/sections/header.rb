module Psd
  module Read
    module Sections
      class Header
        SIGNATURE   = "8BPS"

        VERSION_PSD = 1
        VERSION_PSB = 2

        LENGTH_SIGNATURE = 4
        LENGTH_RESERVED  = 6

        PIXELS_MAX_PSD = 30000
        PIXELS_MAX_PSB = 300000

        SUPPORTED_DEPTH = [1,8,16,32]

        attr_reader :channels, :color_mode, :depth, :height, :width

        def initialize(stream)
          Psd::LOG.info("### HEADER ###")
          @stream = stream
        end

        def parse
          signature = BinData::String.new(read_length: LENGTH_SIGNATURE).read(@stream)
          unless signature == SIGNATURE
            raise Psd::SignatureMismatch.new("PSD/PSB signature mismatch")
          end

          version = BinData::Uint16be.read(@stream)
          unless version == VERSION_PSD || version == VERSION_PSB
            raise Psd::VersionMismatch.new("PSD/PSB version mismatch")
          end

          reserved = BinData::Uint48be.read(@stream)
          unless reserved == 0
            raise "Reserved header must be 0"
          end

          @channels = BinData::Uint16be.read(@stream)
          if channels < 1 || channels > 56
            raise Psd::ChannelsRangeOutOfBounds.new("Channels supported is 1 to 56, excpected: #{channels}")
          end

          @height = BinData::Uint32be.read(@stream)
          @width  = BinData::Uint32be.read(@stream)

          if version == VERSION_PSD
            if width < 1 || width > PIXELS_MAX_PSD || height < 1 || height > PIXELS_MAX_PSD
              raise Psd::SizeOutOfBounds.new("Out of bounds: width: #{width}px, height: #{height}px")
            end
          else
            if width < 1 || width > PIXELS_MAX_PSB || height < 1 || height > PIXELS_MAX_PSB
              raise Psd::SizeOutOfBounds.new("Out of bounds: width: #{width}px, height: #{height}px")
            end
          end

          @depth = BinData::Uint16be.read(@stream)
          unless SUPPORTED_DEPTH.include? @depth
            raise Psd::DepthNotSupported("Depth #{@depth} is not supported.")
          end

          @color_mode = BinData::Uint16be.read(@stream)
          unless Psd::COLOR_MODE.include? @color_mode
            raise Psd::ColorModeNotSupported("Color mode #{@color_mode} is not supported.")
          end
        end
      end
    end
  end
end
