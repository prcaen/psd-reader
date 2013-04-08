module Psd
  module Read
    module Objects
      class Layer
        LENGTH_SIGNATURE     = 4
        BLEND_MODE_SIGNATURE = "8BIM"

        CHANNEL_SUFFIXES = {
          -3 => "real layer mask",
          -2 => "layer mask",
          -1 => "A",
           0 => "R",
           1 => "G",
           2 => "B",
           3 => "RGB",
           4 => "CMYK",
           5 => "HSL",
           6 => "HSB",
           9 => "Lab",
          11 => "RGB",
          12 => "Lab",
          13 => "CMYK"
        }

        SECTION_DIVIDER_TYPES = {
          0 => "other",
          1 => "open_folder",
          2 => "closed_folder",
          3 => "bounding"
        }

        attr_reader :mask, :blending_ranges, :adjustments, :layer_type, :blending_mode, :opacity, :visible
        attr_reader :width, :height, :top, :left, :right, :bottom, :channels, :channels_info, :name

        def initialize(stream, header, layer_index)
          @stream      = stream
          @header      = header
          @layer_index = layer_index

          @image = nil

          @adjustements   = {}
          @blending_mode  = {}
          @blending_range = {}
          @mask           = {}

          @layer_type    = "normal"
          @opacity       = 255

          @folder        = false
          @hidden        = false
          @bounding      = false
        end

        def parse
          return if @layer_index == nil
          Psd::LOG.info("Parsing layer #{@layer_index}")

          parse_infos
          parse_blend_mode

          extra_length = BinData::Uint32be.read(@stream).value

          if extra_length > 0
            parse_layer_mask_adjustment_layer_data
            parse_layer_blending_ranges_data
          end
        end

        def parse_infos
          @top      = BinData::Int32be.read(@stream).value
          @left     = BinData::Int32be.read(@stream).value
          @bottom   = BinData::Int32be.read(@stream).value
          @right    = BinData::Int32be.read(@stream).value
          @channels = BinData::Int16be.read(@stream).value

          @width  = @right - @left
          @height = @bottom - @top

          Psd::LOG.debug("Coordinates - top: #{@top}, bottom: #{@bottom}, left: #{@left}, right: #{@right}, channels: #{@channels}")
          Psd::LOG.debug("Dimensions  - width: #{@width}px, height: #{@height}px")

          if @bottom < @top || @right < @left || @channels > 64
            Psd::LOG.error("Somethings not right, skip")
            @stream.seek(6 * @channels + 12)

            return
          end

          @channels_info = {}

          i = 0
          while i < @channels
            id     = BinData::Int16be.read(@stream).value
            length = BinData::Int32be.read(@stream).value if @header.version == Psd::Read::Sections::Header::VERSION_PSD
            length = BinData::Int64be.read(@stream).value if @header.version == Psd::Read::Sections::Header::VERSION_PSB

            channel = {
              id: id,
              length: length
            }

            Psd::LOG.debug("Channel #{i}: id = #{id}, bytes = #{length}, type = #{CHANNEL_SUFFIXES[id]}")
            @channels_info[i] = channel

            i += 1
          end
        end

        def parse_blend_mode
          @blending_mode = {}

          signature = BinData::String.new(read_length: LENGTH_SIGNATURE).read(@stream).value
          raise Psd::SignatureMismatch.new("PSD/PSB signature mismatch") unless signature == BLEND_MODE_SIGNATURE

          @blending_mode[:key]      = BinData::String.new(read_length: 4).read(@stream).value.strip
          @blending_mode[:opacity]  = BinData::Uint8be.read(@stream).value
          @blending_mode[:clipping] = BinData::Uint8be.read(@stream).value

          @blending_mode[:transparency_protected] =  BinData::Bit1.read(@stream).value
          @blending_mode[:visible]                = !BinData::Bit1.read(@stream).value
          @blending_mode[:obsolete]               =  BinData::Bit1.read(@stream).value

          if BinData::Bit1.read(@stream).value > 0
            @blending_mode[:pixel_data_irrelevant] = BinData::Bit1.read(@stream).value
          else
            BinData::Bit1.read(@stream).value
          end

          BinData::Skip.new(length: (1/2)).read(@stream)

          filler = BinData::Uint8be.read(@stream).value

          @opacity = @blending_mode[:opacity]
          @visible = @blending_mode[:visible]

          Psd::LOG.debug("Blending mode: #{@blending_mode}")
        end

        def parse_layer_mask_adjustment_layer_data
          data_size = BinData::Uint32be.read(@stream).value

          if data_size > 0
            @mask[:top]    = BinData::Int32be.read(@stream).value
            @mask[:left]   = BinData::Int32be.read(@stream).value
            @mask[:bottom] = BinData::Int32be.read(@stream).value
            @mask[:right]  = BinData::Int32be.read(@stream).value

            @mask[:default_color] = BinData::Uint8be.read(@stream).value

            @mask[:relative_position] = BinData::Bit1.read(@stream).value
            @mask[:disabled]          = BinData::Bit1.read(@stream).value
            @mask[:invert]            = BinData::Bit1.read(@stream).value
            BinData::Skip.new(length: (5/8)).read(@stream)

            if @mask[:data_size] === 20
              BinData::Skip.new(length: 2).read(@stream)
            else
              @mask[:relative_position] = BinData::Bit1.read(@stream).value
              @mask[:disabled]          = BinData::Bit1.read(@stream).value
              @mask[:invert]            = BinData::Bit1.read(@stream).value
              BinData::Skip.new(length: (5/8)).read(@stream)

              BinData::Skip.new(length: 1).read(@stream)
              BinData::Skip.new(length: 16).read(@stream)
            end

            Psd::LOG.debug("Mask: #{@mask}")
          end
        end

        def parse_layer_blending_ranges_data
        end
      end
    end
  end
end
