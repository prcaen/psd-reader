require "psd/read/tools"
require "psd/read/types/pascal_string"
require "psd/read/sections/header"
require "psd/read/sections/color_mode_data"
require "psd/read/sections/image_resources"
require "psd/read/sections/layer_and_mask_information"
require "psd/read/sections/image_data"

module Psd
  class Reader
    def initialize(file_path)
      raise ENOENT.new("#{file_path}") unless File.exist?(file_path)

      @file_path = file_path
      @filename  = File.basename(file_path)
      @parsed    = false
      Psd::LOG.info("#### READ FILE: #{@filename} ####")

      @stream = File.open(file_path, "rb")

      # Header
      @header = Psd::Read::Sections::Header.new(@stream)
      @header.parse
    end

    def parse
      start_parse = Time.now
      @stream.seek(LENGTH_HEADER_TOTAL)

      # Color mode data
      @color_mode_data = Psd::Read::Sections::ColorModeData.new(@stream, color_mode(false))
      @color_mode_data.skip

      # Image resources
      @image_resources = Psd::Read::Sections::ImageResources.new(@stream, color_mode(false))
      @image_resources.skip

      # Layer and Mask Information
      @layer_and_mask_information = Psd::Read::Sections::LayerAndMaskInformation.new(@stream, @header)
      @layer_and_mask_information.parse

      # Image Data
      @image_data = Psd::Read::Sections::ImageData.new(@stream, color_mode(false))
      @image_data.parse

      @parsed   = true
      end_parse = Time.now
      Psd::LOG.debug("File parsed in: #{Psd::Read::Tools::format_time_diff(start_parse, end_parse)}")
      Psd::LOG.info("#### END READ FILE: #{@filename} ####")
      Psd::LOG.info("Summary => #{self.to_s}")
    end

    def to_s
      "Filename: #{@filename}, channels: #{channels}, width: #{width(true)}, height: #{height(true)}, depth: #{depth(true)}, color mode: #{color_mode}, resources length: #{resources_length(true)}, size: #{Psd::Read::Tools.format_size(File.size(@file_path))}, created at: #{File.ctime(@file_path)}, updated at: #{File.mtime(@file_path)}, path: #{File.dirname(@file_path)}"
    end

    def parsed?
      @parsed
    end

    def channels
      @header.channels
    end

    def color_mode(humanize = true)
      if humanize
        COLOR_MODES[@header.color_mode]
      else
        @header.color_mode
      end
    end

    def depth(humanize = false)
      if humanize
        "#{@header.depth}bits per channel"
      else
        @header.depth
      end
    end

    def height(humanize = false)
      if humanize
        "#{@header.height}px"
      else
        @header.height
      end
    end

    def resources
      raise UnParsedException.new("Image resources are not parsed") unless @image_resources.parsed?
      @image_resources.resources
    end

    def resources_length(humanize = false)
      len = @image_resources.resources.length
      if humanize && len == 0
        "N/A"
      else
        len
      end
    end

    def width(humanize = false)
      if humanize
        "#{@header.width}px"
      else
        @header.width
      end
    end

    def version_psd?
      @header.version == VERSION_PSD
    end

    def version_psb?
      @header.version == VERSION_PSB
    end
  end
end
