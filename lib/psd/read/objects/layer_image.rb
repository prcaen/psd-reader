module Psd
  module Read
    module Objects
      class LayerImage
        attr_reader :width, :height, :depth, :channels

        def initialize(stream, header, layer)
          @stream = stream
          @header = header
          @layer  = layer

          @channels_info = @layer.channels_info
          @channels_data = []
          @width         = @layer.width
          @height        = @layer.height
          @number_pixels = @width * @height
          @pixels_count  = @width * @height
          @pixels_count *= 2 if depth == 16
          @pixels = {}

          @length = length
        end

        def parse
          LOG.info("Parsing layer - #{@layer.name}")

          @channel_pos = 0
          i = 0

          while i < channels do
            @channel_info = @layer.channels_info[i]

            if @channel_info[:length] <= 0
              @compression = BinData::Int16be.read(@stream).value
              next
            end

            if @channel_info[:length] == -2
              @width  = @layer.mask[:width]
              @height = @layer.mask[:height]
            else
              @width  = @layer.width
              @height = @layer.height
            end

            LOG.debug("Channel ##{@channel_info[:id]}: length = #{@channel_info[:length]}")

            before_parse = @stream.tell
            parse_image_data
            after_parse  = @stream.tell

            if after_parse != before_parse + @channel_info[:length]
              raise Exception.new("Read incorrect number of bytes for channel ##{@channel_info[:id]}. Layer=#{@layer.name}, Expected = #{before_parse + @channel_info[:length]}, Actual: #{after_parse}")
              BinData::Skip.new(length: before_parse + @channel_info[:length]).read(@stream)
            end

            i += 1
          end
        end

        private

        def bytes_count
          bytes_count = {}

          i = 0
          while i < @height
            bytes_count[i] = BinData::Int16be.read(@stream).value

            i += 1
          end

          bytes_count
        end

        def channels
          @layer.channels
        end

        def depth
          @header.depth
        end

        def length
          case @header.depth
          when 1
            len = (@width + 7) / 8 * @height
          when 16
            len = @width * @height * 2
          else
            len = @width * @height
          end

          @channel_length = len

          len *= channels
        end

        def parse_compression
          BinData::Int16be.read(@stream).value
        end

        def parse_image_data
          @compression = parse_compression

          case @compression
          when COMPRESSION_RAW_DATA
            parse_raw
          when COMPRESSION_RLE_COMPRESSED
            parse_rle
          when COMPRESSION_ZIP
          when COMPRESSION_ZIP_PREDICTION
            parse_zip
          else
            LOG.warn("Unknown image compression. Attempting to skip.")
            BinData::Skip.new(length: @end).read(@stream)
          end

          process_image_data
        end

        def parse_raw
          LOG.debug("Parse RAW")
          data = BinData::String.new(read_length: @channel_info[:length] - 2).read(@stream).value
          data_index = 0;
          i = channel_pos
          ref = channel_pos + @channel_info[:length] - 2

          while i < ref
            @channels_data[i] = data[data_index]
            data_index += 1
            i += 1
          end
        end

        def parse_rle
          LOG.debug("Parse RLE")
          @bytes_count = bytes_count
          LOG.debug("Read byte counts. Current pos = #{@stream.tell}, Pixels = #{@length}px")

          parse_channel_data
        end

        def parse_zip
          raise "Parse ZIP - Not yet implemented"
        end

        def parse_channel_data
          LOG.debug("Parsing layer channel ##{@channel_info[:id]}, Start = #{@stream.tell}")
          decode_rle_channel
        end

        def decode_rle_channel
          i = 0
          line_index = 0

          start_time = Time.now
          while i < @height do
            byte_count = @bytes_count[line_index]
            line_index += 1

            start = @stream.tell

            while @stream.tell < start + byte_count do
              len = BinData::Uint8be.read(@stream).value

              if len < 128
                len += 1
                data = @stream.read(len).unpack("C#{len}")

                k = @channel_pos
                data_index = 0

                ref = k + len
                while k < ref do
                  @channels_data[k] = data[data_index].to_i
                  data_index += 1
                  k += 1
                end

                @channel_pos += len
              elsif len > 128
                len ^= 0xff
                len += 2

                val = BinData::Uint8be.read(@stream).value
                data = {}
                k = @channel_pos
                data_index = 0
                z = 0

                while z < len do
                  data[z] = val
                  z += 1
                end

                ref = k + len
                while k < ref do
                  @channels_data[k] = data[data_index]
                  data_index += 1
                  k += 1
                end

                @channel_pos += len
              end
            end
            i += 1
          end
          end_time = Time.now

          LOG.debug("Time decode RLE: #{Tools.format_time_diff(start_time, end_time)}")
        end

        def process_image_data
          if depth === 8 || depth === 16
            start_time = Time.now

            case @header.color_mode
            when COLOR_GRAYSCALE
              combine_grayscale_channels(depth)
            when COLOR_RGB
              combine_rbg_channels(depth)
            when COLOR_CMYK
              combine_cmyk_channels(depth)
            when COLOR_MULTICHANNEL
              combine_multichannel_channels(depth)
            when COLOR_LAB
              combine_lab_channels(depth)
            end

            end_time = Time.now
            LOG.debug("Time combine colors: #{Tools.format_time_diff(start_time, end_time)}")
          end
        end

        def combine_rbg_channels(depth)
          i = 0
          ref = @number_pixels

          if depth === 8
            while i < ref do
              index = 0
              pixel = { r: 0, g: 0, b: 0, a: 255 }

              @channels_info.each do |key, channel|
                case channel[:id]
                when -1
                  if @layer.channels === 4
                    pixel[:a] = get_pixel_color(i, index)
                  else
                    next
                  end
                when 0
                  pixel[:r] = get_pixel_color(i, index)
                when 1
                  pixel[:g] = get_pixel_color(i, index)
                when 2
                  pixel[:b] = get_pixel_color(i, index)
                end

                index += 1
              end

              pixel[:a] = get_alpha_value(pixel[:a])
              @pixels[i] = pixel

              i += 1
            end
          elsif depth === 16
            while i < ref do
              index = 0
              pixel = { r: 0, g: 0, b: 0, a: 255 }

              @channels_info.each do |key, channel|
                b1 = @channel_data[i + (@channel_length * index) + 1];
                b2 = @channel_data[i + (@channel_length * index)];

                case channel[:id]
                when -1
                  if @layer.channels === 4
                    pixel[:a] = Tools::to_uint16(b1, b2)
                  else
                    next
                  end
                when 0
                  pixel[:r] = Tools::to_uint16(b1, b2)
                when 1
                  pixel[:g] = Tools::to_uint16(b1, b2)
                when 2
                  pixel[:b] = Tools::to_uint16(b1, b2)
                end

                index += 1
              end

              pixel[:a] = get_alpha_value(pixel[:a])
              @pixels[i] = pixel

              i += 1
            end
          end
        end

        def combine_grayscale_channels(depth)
          LOG.warn("Combine grayscale - Not yet implemented")
        end

        def combine_cmyk_channels(depth)
          LOG.warn("Combine CMYK - Not yet implemented")
        end

        def combine_multichannel_channels(depth)
          LOG.warn("Combine multichannel - Not yet implemented")
        end

        def combine_lab_channels(depth)
          LOG.warn("Combine lab - Not yet implemented")
        end

        def get_pixel_color(i, index)
          @channels_data[i + @channel_length * index]
        end

        def get_alpha_value(alpha)
          if alpha == nil
            alpha = 255
          end

          if @layer != nil
            alpha *= @layer.opacity.to_f / 255
          end

          alpha.to_i
        end
      end
    end
  end
end
