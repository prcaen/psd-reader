require "logger"
require "bindata"
require "psd/version"

module Psd
  #  =================
  #  =   CONSTANTS   =
  #  =================
  SIGNATURE   = "8BPS"
  VERSION_PSD = 1
  VERSION_PSB = 2

  #  =================
  #  =      LOGS     =
  #  =================
  if defined?(Rails)
    LOG = Rails.logger
  else
    LOG = Logger.new(STDOUT)
    LOG.level = Logger::DEBUG
  end

  #  =================
  #  =   EXCEPTIONS  =
  #  =================
  class Exception < ::Exception
    def initialize(mess)
      LOG.error(mess) unless mess.nil? or mess.empty?
    end
  end
  class SignatureMismatch < Psd::Exception
  end

  class VersionMismatch < Psd::Exception
  end

  class EndFileReached < Psd::Exception
  end
end

require "psd/reader"
require "psd/writer"
