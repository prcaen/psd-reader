require "psd/read/blocks/image_resource"

module Psd
  module Read
    module Sections
      class ImageResources
        attr_reader :resources

        def initialize(stream, color_mode)
          @stream     = stream
          @color_mode = color_mode
          @resources  = []
          @length     = BinData::Int32be.read(@stream).value
          @parsed     = false
        end

        def parse
          Psd::LOG.info("### IMAGE RESOURCES ###")
          Psd::LOG.debug("Current position: #{Psd::Read::Tools.format_size(@stream.pos)}")

          n = @length

          start = @stream.pos

          while n > 0 do
            pos = @stream.pos
            image_resource = Psd::Read::Blocks::ImageResource.new(@stream, @color_mode)
            image_resource.parse

            @resources.push(image_resource)

            n -= @stream.pos - pos
          end

          @stream.seek(start + @length)
          @parsed = true
        end

        def skip
          Psd::LOG.info("### IMAGE RESOURCES - Skipped ###")
          BinData::Skip.new(length: @length).read(@stream)
        end

        def parsed?
          @parsed
        end
      end
    end
  end
end
