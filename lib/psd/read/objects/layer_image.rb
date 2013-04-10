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
          @width         = @layer.width
          @height        = @layer.height
          @pixels_count  = @width * @height
          @pixels_count *= 2 if depth == 16

          @length = length
        end

        def parse
          Psd::LOG.info("Parsing layer - #{@layer.name}")

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

            Psd::LOG.debug("Channel ##{@channel_info[:id]}: length = #{@channel_info[:length]}")

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
          while i <= @height
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
            Psd::LOG.warn("Unknown image compression. Attempting to skip.")
            BinData::Skip.new(length: @end).read(@stream)
          end
        end

        def parse_raw
        end

        def parse_rle
        end

        def parse_zip
        end
      end
    end
  end
end
