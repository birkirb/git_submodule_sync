require 'logger'

log_dir = File.join(File.dirname(__FILE__), "../log")
FileUtils.mkdir_p(log_dir) unless File.exist?(log_dir)
$logger = Logger.new(File.join(log_dir, "monitor.log"))
$logger.info("Loading...")
