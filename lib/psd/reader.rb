require "psd/read/sections/header"

module Psd
  class Reader
    def initialize(file_path)
      Psd::LOG.info("#### READ FILE: #{File.basename(file_path)} ####") unless file_path.empty?

      stream = File.open(file_path, "rb")
      Psd::Read::Sections::Header.new(stream).parse
    end
  end
end
