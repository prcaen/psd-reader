module Psd
  #  =================
  #  =   CONSTANTS   =
  #  =================
  BITMAP       = 0
  GRAYSCALE    = 1
  INDEXED      = 2
  RGB          = 3
  CMYK         = 4
  MULTICHANNEL = 7
  DUOTONE      = 8
  LAB          = 9

  COLOR_MODE = [BITMAP, GRAYSCALE, INDEXED, RGB, CMYK, MULTICHANNEL, DUOTONE, LAB]

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
end
