module Psd
  module Read
    module Blocks
      class ImageResource
        LENGTH_SIGNATURE = 4
        SIGNATURE = "8BIM"
        def initialize(stream, color_mode)
          @stream     = stream
          @color_mode = color_mode
        end

        def parse
          signature = BinData::String.new(read_length: LENGTH_SIGNATURE).read(@stream)
          unless signature == SIGNATURE
            raise Psd::SignatureMismatch.new("PSD/PSB signature mismatch")
          end

          @id       = BinData::Uint16be.read(@stream)
          @name     = parse_name
          @size     = Psd::Read::Tools.padding_2(BinData::Int32be.read(@stream))
          @data     = parse_data

          Psd::LOG.debug("Resource ##{@id}, #{@description}")
        end

        def parse_name
          length = BinData::Uint8be.read(@stream)
          length = Psd::Read::Tools.padding_2(length - 1) + 1
          BinData::String.new(read_length: length).read(@stream)
        end

        def parse_data
          if (@id >= 2000 && @id <= 2997) || (@id == 2999)
            @description = "Path Information"
            BinData::Skip.new(length: @size).read(@stream)
          elsif @id >= 4000 && @id <= 4999
            @description = "Plug-In resource(s)"
            BinData::Skip.new(length: @size).read(@stream)
          elsif !ressources_descriptions[@id].nil?
            resource = ressources_descriptions[@id]
            @description = resource[:name]
            unless resource[:parse].nil?
              resource[:parse].call
            else
              BinData::Skip.new(length: @size).read(@stream)
            end
          else
            BinData::Skip.new(length: @size).read(@stream)
          end
        end

        def ressources_descriptions
          {
          1000 => {
            name: "PS2.0 mode data",
            parse: lambda {
              {
                channels: BinData::Uint16be.read(@stream),
                rows: BinData::Uint16be.read(@stream),
                cols: BinData::Uint16be.read(@stream),
                depth: BinData::Uint16be.read(@stream),
                mode: BinData::Uint16be.read(@stream)
              }
            }
          },
          1001 => {
            name: "Macintosh print record"
          },
          1003 => {
            name: "PS2.0 indexed color table"
          },
          1005 => {
            name: "ResolutionInfo"
          },
          1006 => {
            name: "Names of the alpha channels"
          },
          1007 => {
            name: "DisplayInfo"
          },
          1008 => {
            name: "Caption",
            parse: lambda { Huloa::Parsers::Psd::Tools::BinData.pascal_string(@stream) }
          },
          1009 => {
            name: "Border information",
            parse: lambda {
              {
                border_width: BinData::FloatBe.read(@stream),
                unit: lambda {
                  case BinData::Uint16be.read(@stream)
                  when 1
                    "inches"
                  when 2
                    "cm"
                  when 3
                    "points"
                  when 4
                    "picas"
                  when 5
                    "columns"
                  end
                }
              }
            }
          },
          1010 => {
            name: "Background color"
          },
          1011 => {
            name: "Print flags",
            parse: lambda {
              start = @stream.tell
              data = {
                labels: BinData::Uint8be.read(@stream),
                crop_marks: BinData::Uint8be.read(@stream),
                color_bars: BinData::Uint8be.read(@stream),
                registration_marks: BinData::Uint8be.read(@stream),
                negative: BinData::Uint8be.read(@stream),
                flip: BinData::Uint8be.read(@stream),
                interpolate: BinData::Uint8be.read(@stream),
                caption: BinData::Uint8be.read(@stream),
                print_flags: BinData::Uint8be.read(@stream)
              }

              @stream.seek(start + @size)
            }
          },
          1012 => {
            name: "Grayscale/multichannel halftoning info"
          },
          1013 => {
            name: "Color halftoning info"
          },
          1014 => {
            name: "Duotone halftoning info"
          },
          1015 => {
            name: "Grayscale/multichannel transfer function"
          },
          1016 => {
            name: "Color transfer functions"
          },
          1017 => {
            name: "Duotone transfer functions"
          },
          1018 => {
            name: "Duotone image info"
          },
          1019 => {
            name: "B&W values for the dot range",
            parse: lambda { BinData::Uint16be.read(@stream) }
          },
          1021 => {
            name: "EPS options"
          },
          1022 => {
            name: "Quick Mask info",
            parse: lambda {
              {
                quick_mask_channel_id: BinData::Uint16be.read(@stream),
                was_mask_empty: BinData::Uint8be.read(@stream)
              }
            }
          },
          1024 => {
            name: "Layer state info",
            parse: lambda { BinData::Uint16be.read(@stream) }
          },
          1025 => {
            name: "Working path"
          },
          1026 => {
            name: "Layers group info",
            parse: lambda {
              start = @stream.tell

              results = []

              while @stream.tell < start + @size
                info = BinData::Uint16be.read(@stream)[0]
                results.push(info)
              end

              results
            }
          },
          1028 => {
            name: "IPTC-NAA record (File Info)"
          },
          1029 => {
            name: "Image mode for raw format files"
          },
          1030 => {
            name: "JPEG quality"
          },
          1032 => {
            name: "Grid and guides info"
          },
          1033 => {
            name: "Thumbnail resource"
          },
          1034 => {
            name: "Copyright flag",
            parse: lambda {}
          },
          1035 => {
            name: "URL",
            parse: lambda {
              @stream.read(@size)
            }
          },
          1036 => {
            name: "Thumbnail resource"
          },
          1037 => {
            name: "Global Angle"
          },
          1038 => {
            name: "Color samplers resource"
          },
          1039 => {
            name: "ICC Profile"
          },
          1040 => {
            name: "Watermark",
            parse: lambda {
              BinData::Uint8be.read(@stream)
            }
          },
          1041 => {
            name: "ICC Untagged"
          },
          1042 => {
            name: "Effects visible",
            parse: lambda {
              BinData::Uint8be.read(@stream)
            }
          },
          1043 => {
            name: "Spot Halftone",
            parse: lambda {
              version = BinData::Uint32be.read(@stream)
              length  = BinData::Uint32be.read(@stream)

              {
                version: version,
                data: @stream.read(length)
              }
            }
          },
          1044 => {
            name: "Document specific IDs seed number",
            parse: lambda {
              @doc_id_seed_number = BinData::Uint32be.read(@stream)
            }
          },
          1045 => {
            name: "Unicode Alpha Names"
          },
          1046 => {
            name: "Indexed Color Table Count",
            parse: lambda {
              @indexed_color_table_count = BinData::Uint16be.read(@stream)
            }
          },
          1047 => {
            name: "Transparent Index",
            parse: lambda {
              @transparancy_index = BinData::Uint16be.read(@stream)
            }
          },
          1049 => {
            name: "Global Altitude",
            parse: lambda {
              @global_altitude = BinData::Uint32be.read(@stream)
            }
          },
          1050 => {
            name: "Slices"
          },
          1051 => {
            name: "Workflow URL",
            parse: lambda {
              @workflow_url = Huloa::Parsers::Psd::Tools::BinData.pascal_string(@stream)
            }
          },
          1052 => {
            name: "Jump To XPEP",
            parse: lambda {
              @major_version = BinData::Uint16be.read(@stream)
              @minor_version = BinData::Uint16be.read(@stream)
              count          = BinData::Uint32be.read(@stream)

              @xpep_blocks = []

              i = _i = 0

              while 0 <= count ? _i < count : _i > count
                block = {
                  size: BinData::Uint32be.read(@stream),
                  key: @stream.read(4)
                }

                if block[:key] == "jtDd"
                  block[:dirty] = Huloa::Parsers::Psd::Tools::BinData.read_boolean(@stream)
                else
                  block[:mod_date] = BinData::Uint32be.read(@stream)
                end

                @xpep_blocks.push(block)
                i = 0 <= count ? _i += 1 : _i -= 1
              end

              @xpep_blocks
            }
          },
          1053 => {
            name: "Alpha Identifiers"
          },
          1054 => {
            name: "URL List"
          },
          1057 => {
            name: "Version Info"
          },
          1058 => {
            name: "EXIF data 1"
          },
          1059 => {
            name: "EXIF data 3"
          },
          1060 => {
            name: "XMP metadata"
          },
          1061 => {
            name: "Caption digest"
          },
          1062 => {
            name: "Print scale"
          },
          1064 => {
            name: "Pixel Aspect Ratio"
          },
          1065 => {
            name: "Layer Comps"
          },
          1066 => {
            name: "Alternate Duotone Colors"
          },
          1067 => {
            name: "Alternate Spot Colors"
          },
          1069 => {
            name: "Layer Selection ID(s)"
          },
          1070 => {
            name: "HDR Toning information"
          },
          1071 => {
            name: "Print info"
          },
          1072 => {
            name: "Layer Groups Enabled"
          },
          1073 => {
            name: "Color samplers resource"
          },
          1074 => {
            name: "Measurement Scale"
          },
          1075 => {
            name: "Timeline Information"
          },
          1076 => {
            name: "Sheet Disclosure"
          },
          1077 => {
            name: "DisplayInfo"
          },
          1078 => {
            name: "Onion Skins"
          },
          1080 => {
            name: "Count Information"
          },
          1082 => {
            name: "Print Information"
          },
          1083 => {
            name: "Print Style"
          },
          1084 => {
            name: "Macintosh NSPrintInfo"
          },
          1085 => {
            name: "Windows DEVMODE"
          },
          2999 => {
            name: "Name of clipping path"
          },
          7000 => {
            name: "Image Ready variables"
          },
          7001 => {
            name: "Image Ready data sets"
          },
          8000 => {
            name: "Lightroom workflow",
            parse: lambda { @lightroom_workflow = 1 }

          },
          10000 => {
            name: "Print flags info",
            parse: lambda {
              @version = BinData::Uint16be.read(@stream)
              @center_crop_marks = BinData::Uint8be.read(@stream)
              BinData::Skip.new(length: 1).read(@stream)
              @bleed_width = BinData::Uint32be.read(@stream)
              @bleed_scale = BinData::Uint16be.read(@stream)
            }
          }
        }
        end
      end
    end
  end
end