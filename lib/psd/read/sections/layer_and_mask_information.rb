require "psd/read/blocks/layer_info"

module Psd
  module Read
    module Sections
      class LayerAndMaskInformation
        def initialize(stream, header)
          @stream     = stream
          @header     = header
          @parsed     = false

          @layers       = []
          @merged_alpha = false
          @global_mask  = {}
          @extras       = []
        end

        def parse
          Psd::LOG.info("### LAYERS AND MASK INFORMATION ###")
          mask_size    = BinData::Uint32be.read(@stream) if @header.version == Psd::Read::Sections::Header::VERSION_PSD
          mask_size    = BinData::Uint64be.read(@stream) if @header.version == Psd::Read::Sections::Header::VERSION_PSB
          end_location = @stream.tell + mask_size
          Psd::LOG.debug("Layer mask size: #{Psd::Read::Tools.format_size(mask_size)}")
          return if mask_size <= 0

          Psd::Read::Blocks::LayerInfo.new(@stream, @header).parse
        end
      end
    end
  end
end
