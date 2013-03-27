module Psd
  #  =================
  #  =   CONSTANTS   =
  #  =================
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
end
