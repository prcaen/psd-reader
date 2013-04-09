require "psd/read/objects/layer"

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
          if @header.version == Psd::Read::Sections::Header::VERSION_PSD
            layer_info_size = Psd::Read::Tools.padding_2(BinData::Int32be.read(@stream).value)
          else
            layer_info_size = Psd::Read::Tools.padding_2(BinData::Int64be.read(@stream).value)
          end

          pos = @stream.pos

          if layer_info_size > 0
            layer_count = BinData::Uint16be.read(@stream).value

            if layer_count < 0
              Psd::LOG.debug("First alpha channel contains transparency data")
              layer_count  = layer_count.abs
              @merged_alpha = true
            end

            if layer_count * (18 + 6 * @header.channels) > layer_info_size
              raise "Unlikely number of #{layer_count} layers for #{@header.channels} with #{layer_info_size} layer info size. Giving up."
            end

            Psd::LOG.debug("Found #{layer_count} layer(s)")

            i = 0
            while i < layer_count do
              layer = Psd::Read::Objects::Layer.new(@stream, @header, i)
              layer.parse
              @layers.push(layer)

              i += 1
            end
          end
        end
      end
    end
  end
end
