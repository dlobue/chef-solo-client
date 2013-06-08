require 'chef/handler/error_report'

Chef::Config[:exception_handlers] << Chef::Handler::ErrorReport.new
Chef::Config[:exception_handlers] << Chef::Handler::SNSReporter.new

