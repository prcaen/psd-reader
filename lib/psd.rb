require "logger"
require "bindata"

module Psd
  #  =================
  #  =      LOGS     =
  #  =================
  if defined?(Rails)
    LOG = Rails.logger
  else
    LOG = Logger.new(STDOUT)
    LOG.level = Logger::DEBUG
  end
end

require "psd/version"
require "psd/constants"
require "psd/exceptions"

require "psd/reader"
require "psd/writer"
