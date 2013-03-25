module Psd
  module Read
    module Sections
      class Header
        def initialize(stream)
          Psd::LOG.info("### HEADER ###")
          @stream = stream
        end

        def parse
          signature = @stream.read(4).unpack("A4")
          unless signature == Psd::SIGNATURE
            raise Psd::SignatureMismatch.new("PSD/PSB signature mismatch")
          end

          version = @stream.read(2).unpack("s")
          unless version == Psd::VERSION_PSD || version == Psd::VERSION_PSB
            raise Psd::VersionMismatch.new("PSD/PSB version mismatch")
          end
        end
      end
    end
  end
end
