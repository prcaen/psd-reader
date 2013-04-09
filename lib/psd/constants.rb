module Psd
  #  =================
  #  =   CONSTANTS   =
  #  =================
  BLEND_MODES = {
    "norm" => "normal",
    "dark" => "darken",
    "lite" => "lighten",
    "hue"  => "hue",
    "sat"  => "saturation",
    "colr" => "color",
    "lum"  => "luminosity",
    "mul"  => "multiply",
    "scrn" => "screen",
    "diss" => "dissolve",
    "over" => "overlay",
    "hLit" => "hard light",
    "sLit" => "soft light",
    "diff" => "difference",
    "smud" => "exclusion",
    "div"  => "color dodge",
    "idiv" => "color burn",
    "lbrn" => "linear burn",
    "lddg" => "linear dodge",
    "vLit" => "vivid light",
    "lLit" => "linear light",
    "pLit" => "pin light",
    "hMix" => "hard mix"
  }

  CHANNEL_SUFFIXES = {
    -3 => "real layer mask",
    -2 => "layer mask",
    -1 => "A",
     0 => "R",
     1 => "G",
     2 => "B",
     3 => "RGB",
     4 => "CMYK",
     5 => "HSL",
     6 => "HSB",
     9 => "Lab",
    11 => "RGB",
    12 => "Lab",
    13 => "CMYK"
  }

  COLOR_BITMAP       = 0
  COLOR_GRAYSCALE    = 1
  COLOR_INDEXED      = 2
  COLOR_RGB          = 3
  COLOR_CMYK         = 4
  COLOR_MULTICHANNEL = 7
  COLOR_DUOTONE      = 8
  COLOR_LAB          = 9

  COLOR_MODE  = [COLOR_BITMAP, COLOR_GRAYSCALE, COLOR_INDEXED, COLOR_RGB, COLOR_CMYK, COLOR_MULTICHANNEL, COLOR_DUOTONE, COLOR_LAB]
  COLOR_MODES = {
    0 => "Bitmap",
    1 => "GrayScale",
    2 => "Indexed",
    3 => "RGB",
    4 => "CMYK",
    5 => "HSL",
    6 => "HSB",
    7 => "Multichannel",
    8 => "Duotone",
    9 => "Lab",
    10 => "Gray16",
    11 => "RGB48",
    12 => "Lab48",
    13 => "CMYK64",
    14 => "DeepMultichannel",
    15 => "Duotone16"
  }

  LENGTH_HEADER_RESERVED  = 6
  LENGTH_HEADER_TOTAL     = 26
  LENGTH_SIGNATURE        = 4

  PIXELS_MAX_PSD = 30000
  PIXELS_MAX_PSB = 300000

  SECTION_DIVIDER_TYPES = {
    0 => "other",
    1 => "open_folder",
    2 => "closed_folder",
    3 => "bounding"
  }

  SIGNATURE_BLEND_MODE       = "8BIM"
  SIGNATURE_EXTRA_DATA_FIRST = "8BIM"
  SIGNATURE_EXTRA_DATA_LAST  = "8B64"
  SIGNATURE_PSD              = "8BPS"

  SUPPORTED_DEPTH = [1, 8, 16, 32]

  VERSION_PSD = 1
  VERSION_PSB = 2
end
