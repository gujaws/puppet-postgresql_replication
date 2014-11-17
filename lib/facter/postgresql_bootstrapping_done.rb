# postgresql_bootstrap_done.rb

require 'etc'

Facter.add(:postgresql_bootstrapping_done) do
  setcode do
    pw = nil

    begin
      pw = Etc.getpwnam('postgres')
    rescue ArgumentError
    end

    if pw
      File.exist?(File.join(pw.dir, 'bootstrapping-done'))
    else
      false
    end
  end
end
