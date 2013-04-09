require "psd/read/blocks/layer_info"

module Psd
  module Read
    module Sections
      class LayerAndMaskInformation
        attr_reader :layers, :merged_alpha

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
          mask_size    = BinData::Uint32be.read(@stream) if @header.version == VERSION_PSD
          mask_size    = BinData::Uint64be.read(@stream) if @header.version == VERSION_PSB
          end_location = @stream.tell + mask_size
          Psd::LOG.debug("Layer mask size: #{Psd::Read::Tools.format_size(mask_size)}")
          return if mask_size <= 0

          layer_info = Psd::Read::Blocks::LayerInfo.new(@stream, @header)
          layer_info.parse

          @layers       = layer_info.layers
          @merged_alpha = layer_info.merged_alpha
        end
      end
    end
  end
end
