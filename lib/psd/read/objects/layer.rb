module Psd
  module Read
    module Objects
      class Layer
        attr_reader :mask, :blending_ranges, :adjustments, :layer_type, :blending_mode, :opacity, :visible
        attr_reader :width, :height, :top, :left, :right, :bottom, :channels, :channels_info, :name

        attr_accessor :image

        def initialize(stream, header, layer_index)
          @stream      = stream
          @header      = header
          @layer_index = layer_index

          @image = nil

          @adjustements    = {}
          @blending_mode   = {}
          @blending_ranges = {}
          @mask            = {}

          @layer_type    = "normal"
          @opacity       = 255

          @folder        = false
          @visible       = true
          @bounding      = false
        end

        def parse
          return if @layer_index == nil
          Psd::LOG.info("Parsing layer #{@layer_index}")

          parse_infos
          parse_blend_mode

          extra_length = BinData::Int32be.read(@stream).value
          raise "Extra length nil" unless extra_length > 0

          @layer_end = @stream.tell + extra_length

          parse_layer_mask_adjustment_layer_data
          parse_layer_blending_ranges_data
          parse_layer_name
          parse_extra_data
        end

        def bounding?
          @bounding
        end

        def folder?
          @folder
        end

        def hidden?
          !@visible
        end

        def visible?
          @visible
        end

        private

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
          while i < @channels do
            id     = BinData::Int16be.read(@stream).value
            length = BinData::Int32be.read(@stream).value if @header.version == VERSION_PSD
            length = BinData::Int64be.read(@stream).value if @header.version == VERSION_PSB

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
          raise Psd::SignatureMismatch.new("PSD/PSB signature mismatch") unless signature == SIGNATURE_BLEND_MODE

          @blending_mode[:key]      = BinData::String.new(read_length: 4).read(@stream).value.strip
          @blending_mode[:opacity]  = BinData::Uint8be.read(@stream).value
          @blending_mode[:clipping] = BinData::Uint8be.read(@stream).value

          flags  = BinData::Uint8be.read(@stream)
          filler = BinData::Uint8be.read(@stream)

          @blending_mode[:transparency_protected] = !(flags & 0x01)
          @blending_mode[:visible]                = !((flags & (0x01 << 1)) > 0)
          @blending_mode[:obsolete]               = (flags & (0x01 << 2)) > 0

          if (flags & (0x01 << 3)) > 0
            @blending_mode[:pixel_data_irrelevant] = (flags & (0x01 << 4)) > 0
          end

          @blending_mode[:blender] = BLEND_MODES[@blending_mode[:key]]

          @opacity = @blending_mode[:opacity] * 100 / 255
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

            flags = BinData::Uint8be.read(@stream).value

            @mask[:relative_position] = flags & 0x01
            @mask[:disabled]          = (flags & (0x01 << 1)) > 0
            @mask[:invert]            = (flags & (0x01 << 2)) > 0

            if @mask[:data_size] === 20
              BinData::Skip.new(length: 2).read(@stream)
            else
              real_flags           = BinData::Uint8be.read(@stream)
              real_user_mask_bckgd = BinData::Uint8be.read(@stream)

              @mask[:relative_position] = real_flags & 0x01
              @mask[:disabled]          = (real_flags & (0x01 << 1)) > 0
              @mask[:invert]            = (flags & (0x01 << 2)) > 0

              BinData::Skip.new(length: 16).read(@stream)
            end

            Psd::LOG.debug("Mask: #{@mask}")
          end
        end

        def parse_layer_blending_ranges_data
          length = BinData::Int32be.read(@stream).value

          @blending_ranges[:grey] = {
            source: {
              black: BinData::Int16be.read(@stream).value,
              white: BinData::Int16be.read(@stream).value
            },
            dest: {
              black: BinData::Int16be.read(@stream).value,
              white: BinData::Int16be.read(@stream).value
            }
          }

          pos = @stream.tell

          @blending_ranges[:channels_count] = (length - 8) / 8
          raise "Channels cannot be empty" unless @blending_ranges[:channels_count] > 0

          @blending_ranges[:channels] = {}

          i = 0
          while i < @blending_ranges[:channels_count] do
            @blending_ranges[:channels][i] = {
              source: {
                black: BinData::Int16be.read(@stream).value,
                white: BinData::Int16be.read(@stream).value
              },
              dest: {
                black: BinData::Int16be.read(@stream).value,
                white: BinData::Int16be.read(@stream).value
              }
            }

            i += 1
          end

          Psd::LOG.debug("Blending ranges: #{@blending_ranges}")
        end

        def parse_layer_name
          length = Psd::Read::Tools.padding_4(BinData::Uint8be.read(@stream).value)
          @name = BinData::String.new(read_length: length).read(@stream).value
          @name.encode!("UTF-8", "MacRoman")

          Psd::LOG.debug("Name: #{@name}")
        end

        def parse_extra_data
          while @stream.tell < @layer_end do
            signature = BinData::String.new(read_length: LENGTH_SIGNATURE).read(@stream).value
            unless signature == SIGNATURE_EXTRA_DATA_FIRST || signature == SIGNATURE_EXTRA_DATA_LAST
              raise Psd::SignatureMismatch.new("Layer extra data signature error")
            end

            key    = BinData::String.new(read_length: 4).read(@stream).value
            length = Psd::Read::Tools.padding_2(BinData::Uint32be.read(@stream).value)
            pos    = @stream.tell

            Psd::LOG.debug("Layer: #{@name} extra key: #{key}, length: #{length}")

            case key
            when "lsct"
              read_section_divider(length)
            else
              BinData::Skip.new(length: length).read(@stream)
              Psd::LOG.warn("not implemented - skip")
            end
          end
        end

        def read_section_divider(length)
          type = BinData::Int32be.read(@stream).value

          BinData::Skip.new(length: 8).read(@stream) if length === 12

          @layer_type = SECTION_DIVIDER_TYPES[type]
          Psd::LOG.debug("Layer type: #{@layer_type}")

          case type
          when 1
            @folder = true
          when 2
            @folder = true
          when 3
            @bounding = true
          end
        end
      end
    end
  end
end
