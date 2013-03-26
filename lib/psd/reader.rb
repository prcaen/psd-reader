require "psd/read/sections/header"

module Psd
  class Reader
    def initialize(file_path)
      unless file_path.empty?
        @filename = File.basename(file_path)
        Psd::LOG.info("#### READ FILE: #{@filename} ####")
      end

      stream = File.open(file_path, "rb")
      @header = Psd::Read::Sections::Header.new(stream)
      @header.parse

      Psd::LOG.info("#### END READ FILE: #{@filename} ####") unless @filename.nil?
    end

    def to_s
      "Filename: #{@filename}, channels: #{@header.channels}, width: #{@header.width}px, height: #{@header.height}px, depth: #{@header.depth}bits per channel, color mode: #{COLOR_MODES[@header.color_mode]}"
    end
  end
end
