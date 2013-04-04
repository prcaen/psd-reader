module Psd
  #  =================
  #  =   EXCEPTIONS  =
  #  =================
  class Exception < ::Exception
    def initialize(mess)
      super
      LOG.error(mess) unless mess.nil? or mess.empty?
    end
  end
  class SignatureMismatch < Psd::Exception
  end

  class VersionMismatch < Psd::Exception
  end

  class EndFileReached < Psd::Exception
  end

  class ChannelsRangeOutOfBounds < Psd::Exception
  end

  class SizeOutOfBounds < Psd::Exception
  end

  class DepthNotSupported < Psd::Exception
  end

  class ColorModeNotSupported < Psd::Exception
  end

  class LengthException < Psd::Exception
  end

  class UnParsedException < Psd::Exception
  end

  class ENOENT < Errno::ENOENT
    def initialize(mess)
      super
      LOG.error("No such file or directory - #{mess}") unless mess.nil? or mess.empty?
    end
  end
end
