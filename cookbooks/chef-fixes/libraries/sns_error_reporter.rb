#
#   Copyright 2013 Dominic LoBue
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License. 
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#

# not so much a fix so much as a value add. need it in the chef-fixes cookbook
# so it will be picked up by the bootstrap helpers

require 'fog'

class Chef::Handler
  class SNSReporter < Chef::Handler
    def snsconn
      @snsconn ||= Fog::AWS::SNS.new( get_creds )
    end
    def report
      raise "SNS Topic ARN configuration missing!" unless Chef::Config[:sns_report_topic_arn]
      return unless failed? #in case the exception handler is run whenever
                            #an exception is raised, even though the run
                            #completed successfully

      message = "Chef run failed on: "
      message << node.fqdn
      message << "\n"
      if node.attribute? "ec2"
        message << "Instance id: "
        message << node.ec2.instance_id
        message << "\n"
        message << "Instance public hostname: "
        message << node.ec2.public_hostname
        message << "\n"
      end
      message << "Run start time: "
      message << start_time.to_s
      message << "\n"
      message << "Run end time: "
      message << end_time.to_s
      message << "\n"
      message << "Exception: "
      message << run_status.formatted_exception
      message << "\n"
      message << "Stacktrace:"
      message << "\n"
      message << Array(backtrace).join("\n")
      message << "\n"

      snsconn.publish(Chef::Config[:sns_report_topic_arn],
                       message,
                       "Subject" => "Chef run failed on #{node.fqdn}"
                      )
    end
  end
end


