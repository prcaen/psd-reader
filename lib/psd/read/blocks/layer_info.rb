module Psd
  module Read
    module Blocks
      class LayerInfo
        attr_reader :layer_count, :merged_alpha

        def initialize(stream, header)
          @stream     = stream
          @header     = header
          @parsed     = false

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
            @layer_count = BinData::Uint16be.read(@stream).value

            if @layer_count < 0
              Psd::LOG.debug("Note: first alpha channel contains transparency data")
              @layer_count  = @layer_count.abs
              @merged_alpha = true
            end
          end
        end
      end
    end
  end
end
