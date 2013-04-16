require "psd/read/objects/layer"
require "psd/read/objects/layer_image"

module Psd
  module Read
    module Blocks
      class LayerInfo
        attr_reader :layers, :merged_alpha

        def initialize(stream, header)
          @stream     = stream
          @header     = header
          @parsed     = false

          @layers = []
          @merged_alpha = false
        end

        def parse
          layer_info_size = Tools.padding_2(BinData::Int32be.read(@stream).value) if @header.version == VERSION_PSD
          layer_info_size = Tools.padding_2(BinData::Int64be.read(@stream).value) if @header.version == VERSION_PSB

          pos = @stream.pos

          if layer_info_size > 0
            layer_count = BinData::Uint16be.read(@stream).value

            if layer_count < 0
              LOG.debug("First alpha channel contains transparency data")
              layer_count  = layer_count.abs
              @merged_alpha = true
            end

            if layer_count * (18 + 6 * @header.channels) > layer_info_size
              raise Exception.new("Unlikely number of #{layer_count} layers for #{@header.channels} with #{layer_info_size} layer info size. Giving up.")
            end

            LOG.debug("Found #{layer_count} layer(s)")

            i = 0
            while i < layer_count do
              layer = Objects::Layer.new(@stream, @header, i)
              layer.parse
              @layers.push(layer)

              i += 1
            end

            @layers.each do |layer|
              if layer.folder? || layer.bounding?
                LOG.info("Skip #{layer.name} - #{(layer.folder? ? "folder" : "bounding")}")
                BinData::Skip.new(length: 8).read(@stream)
                next
              end

              layer.image = Objects::LayerImage.new(@stream, @header, layer).parse
            end
          end
        end
      end
    end
  end
end
