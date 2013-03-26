module Psd
  module Read
    module Sections
      class Header
        def initialize(stream)
          Psd::LOG.info("### HEADER ###")
          @stream = stream
        end

        def parse
          signature = BinData::String.new(read_length: 4).read(@stream)
          unless signature == Psd::SIGNATURE
            raise Psd::SignatureMismatch.new("PSD/PSB signature mismatch")
          end

          version = BinData::Int16be.read(@stream)
          unless version == Psd::VERSION_PSD || version == Psd::VERSION_PSB
            raise Psd::VersionMismatch.new("PSD/PSB version mismatch")
          end
        end
      end
    end
  end
end
