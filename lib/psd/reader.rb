require "psd/read/sections/header"

module Psd
  class Reader
    def initialize(file_path)
      raise Psd::ENOENT.new("#{file_path}") unless File.exist?(file_path)

      @file_path = file_path
      @filename = File.basename(file_path)
      Psd::LOG.info("#### READ FILE: #{@filename} ####")

      stream = File.open(file_path, "rb")

      # Header
      @header = Psd::Read::Sections::Header.new(stream)
      @header.parse

      Psd::LOG.info("#### END READ FILE: #{@filename} ####")
      Psd::LOG.info("Summary => #{self.to_s}")
    end

    def to_s
      "Filename: #{@filename}, channels: #{@header.channels}, width: #{@header.width}px, height: #{@header.height}px, depth: #{@header.depth}bits per channel, color mode: #{COLOR_MODES[@header.color_mode]}, created at: #{File.ctime(@file_path)}, updated at: #{File.mtime(@file_path)}, path: #{File.dirname(@file_path)}"
    end
  end
end
