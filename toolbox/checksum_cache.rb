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

class Chef::ChecksumCache
  def checksum_file(file, digest)
    @_filename = file
    `cp "#{file}" "#{file + "-orig"}"`
    File.open(file, 'rb') { |f| checksum_io(f, digest) }
  end

  def checksum_io(io, digest)
    fn = @_filename + "__checksummed_data"
    f = File.open(fn, 'wb')
    Chef::Log.debug("Checksummed data at #{fn}")
    while chunk = io.read(1024 * 8)
      digest.update(chunk)
      f.write(chunk)
    end
    @_filename = nil
    f.close()
    digest.hexdigest
  end
end

