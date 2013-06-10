module Psd
  #  =================
  #  =      LOGS     =
  #  =================
  if defined?(Rails)
    LOG = Rails.logger
  else
    LOG = Logger.new(STDOUT)
    LOG.level = Logger::WARN
  end
end
