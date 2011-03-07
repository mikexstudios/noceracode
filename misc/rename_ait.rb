#/usr/bin/env ruby
# Renames files of type ait1_1.bin to ait1_2.bin.

Dir['ait*.bin'].each do |filename|
    #Extract the number of the file
    i = filename.slice(/ait(\d+)_1.bin/, 1)

    #Rename file
    File.rename(filename, 'ait%d_2.bin' % i)
end
