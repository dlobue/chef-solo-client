
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

