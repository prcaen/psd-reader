require "psd/read/blocks/image_resource"

module Psd
  module Read
    module Sections
      class ImageResources
        attr_reader :resources
        def initialize(stream, color_mode)
          Psd::LOG.info("### IMAGE RESOURCES - pos: #{stream.pos} ###")
          @stream     = stream
          @color_mode = color_mode
          @resources  = []
        end

        def parse
          @length = n = BinData::Int32be.read(@stream)

          start = @stream.pos

          while n > 0
            pos = @stream.pos
            image_resource = Psd::Read::Blocks::ImageResource.new(@stream, @color_mode)
            image_resource.parse

            @resources.push(image_resource)

            n -= @stream.pos - pos
          end

          @stream.seek(start + @length)
        end
      end
    end
  end
end
