module Psd
  module Read
    module Blocks
      class ImageResource
        LENGTH_SIGNATURE = 4
        SIGNATURE = "8BIM"

        attr_reader :id, :description, :data

        def initialize(stream, color_mode)
          @stream     = stream
          @color_mode = color_mode
        end

        def parse
          signature = BinData::String.new(read_length: LENGTH_SIGNATURE).read(@stream).value
          unless signature == SIGNATURE
            raise Psd::SignatureMismatch.new("PSD/PSB signature mismatch")
          end

          @id       = BinData::Uint16be.read(@stream).value
          @name     = parse_name
          @size     = Psd::Read::Tools.padding_2(BinData::Int32be.read(@stream).value)
          parse_data

          Psd::LOG.debug("Resource ##{@id}, #{@description}")
        end

        def parse_name
          length = BinData::Uint8be.read(@stream).value
          length = Psd::Read::Tools.padding_2(length - 1) + 1
          BinData::String.new(read_length: length).read(@stream).value
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
              @data = resource[:parse].call
            else
              BinData::Skip.new(length: @size).read(@stream)
            end
          else
            BinData::Skip.new(length: @size).read(@stream)
          end
        end

        # TODO: need tests and refactor
        def ressources_descriptions
          {
          1000 => {
            name: "PS2.0 mode data",
            parse: lambda {
              {
                channels: BinData::Uint16be.read(@stream).value,
                rows: BinData::Uint16be.read(@stream).value,
                cols: BinData::Uint16be.read(@stream).value,
                depth: BinData::Uint16be.read(@stream).value,
                mode: BinData::Uint16be.read(@stream).value
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
            parse: lambda { { caption: Psd::Read::Types::PascalString.new.read(@stream) } }
          },
          1009 => {
            name: "Border information",
            parse: lambda {
              {
                border_width: BinData::FloatBe.read(@stream).value,
                unit: lambda {
                  case BinData::Uint16be.read(@stream).value
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
              {
                labels: BinData::Uint8be.read(@stream).value,
                crop_marks: BinData::Uint8be.read(@stream).value,
                color_bars: BinData::Uint8be.read(@stream).value,
                registration_marks: BinData::Uint8be.read(@stream).value,
                negative: BinData::Uint8be.read(@stream).value,
                flip: BinData::Uint8be.read(@stream).value,
                interpolate: BinData::Uint8be.read(@stream).value,
                caption: BinData::Uint8be.read(@stream).value,
                print_flags: BinData::Uint8be.read(@stream).value
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
            parse: lambda { { b_w_values_for_the_dot_range: BinData::Uint16be.read(@stream).value } }
          },
          1021 => {
            name: "EPS options"
          },
          1022 => {
            name: "Quick Mask info",
            parse: lambda {
              {
                quick_mask_channel_id: BinData::Uint16be.read(@stream).value,
                was_mask_empty: BinData::Uint8be.read(@stream).value
              }
            }
          },
          1024 => {
            name: "Layer state info",
            parse: lambda { { layer_state_info: BinData::Uint16be.read(@stream).value } }
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
                info = BinData::Uint16be.read(@stream).value
                results.push(info)
              end

              { layers_group_info: results }
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
            parse: lambda { { copyright_flag: @stream.read(@size).unpack("C#{@size}") } }
          },
          1035 => {
            name: "URL",
            parse: lambda { { url: @stream.read(@size) } }
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
            parse: lambda { { watermark: BinData::Uint8be.read(@stream).value } }
          },
          1041 => {
            name: "ICC Untagged"
          },
          1042 => {
            name: "Effects visible",
            parse: lambda { { effects_visible: BinData::Uint8be.read(@stream).value } }
          },
          1043 => {
            name: "Spot Halftone",
            parse: lambda {
              version = BinData::Uint32be.read(@stream).value
              length  = BinData::Uint32be.read(@stream).value

              {
                version: version,
                data: @stream.read(length)
              }
            }
          },
          1044 => {
            name: "Document specific IDs seed number",
            parse: lambda { { document_specific_ids_seed_number: BinData::Uint32be.read(@stream).value } }
          },
          1045 => {
            name: "Unicode Alpha Names"
          },
          1046 => {
            name: "Indexed Color Table Count",
            parse: lambda { { indexed_color_table_count: BinData::Uint16be.read(@stream).value } }
          },
          1047 => {
            name: "Transparent Index",
            parse: lambda { { transparancy_index: BinData::Uint16be.read(@stream).value } }
          },
          1049 => {
            name: "Global Altitude",
            parse: lambda { { global_altitude: BinData::Uint32be.read(@stream).value } }
          },
          1050 => {
            name: "Slices"
          },
          1051 => {
            name: "Workflow URL",
            parse: lambda { { workflow_url: Psd::Read::Types::PascalString.new.read(@stream) } }
          },
          1052 => {
            name: "Jump To XPEP",
            parse: lambda {
              major_version = BinData::Uint16be.read(@stream).value
              minor_version = BinData::Uint16be.read(@stream).value
              count         = BinData::Uint32be.read(@stream).value

              xpep_blocks = []

              i = 0

              while i <= count
                block = {
                  size: BinData::Uint32be.read(@stream).value,
                  key: @stream.read(4)
                }

                if block[:key] == "jtDd"
                  block[:dirty] = BinData::Bit1.read(@stream).value
                else
                  block[:mod_date] = BinData::Uint32be.read(@stream).value
                end

                xpep_blocks.push(block)

                i += 1
              end

              { major_version: major_version,
                minor_version: minor_version,
                xpep_blocks: xpep_blocks
              }
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
            parse: lambda { { lightroom_workflow: 1 } }

          },
          10000 => {
            name: "Print flags info",
            parse: lambda {
              version = BinData::Uint16be.read(@stream).value
              center_crop_marks = BinData::Uint8be.read(@stream).value
              BinData::Skip.new(length: 1).read(@stream)
              bleed_width = BinData::Uint32be.read(@stream).value
              bleed_scale = BinData::Uint16be.read(@stream).value

              {
                version: version,
                center_crop_marks: center_crop_marks,
                bleed_width: bleed_width,
                bleed_scale: bleed_scale
              }
            }
          }
        }
        end
      end
    end
  end
end
