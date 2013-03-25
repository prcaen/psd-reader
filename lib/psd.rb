require "psd/version"
require "logger"

module Psd
  #  =================
  #  =   CONSTANTS   =
  #  =================
  SIGNATURE   = "8BPS"
  VERSION_PSD = 1
  VERSION_PSB = 2

  DEBUG_MODE  = false

  #  =================
  #  =      LOGS     =
  #  =================
  LOG = Logger.new('logs/psd.log', 'daily')

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

  class VersionMismatch < Exception
  end

  class EndFileReached < Exception
  end
end

require "psd/reader"
require "psd/writer"
