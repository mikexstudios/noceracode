#!/usr/bin/env ruby
# Usage: 
# 1. First, set the base path by instantiating the class:
#    ep = EchemPath.new('~/Research/Electrochemistry')
# 2. Next, specify any subpaths like:
#    ep.expand('11-12-2011/tafel2/lo-hi/tafel1.csv')
# The function echem_path will expand the path out by searching both the root
# folder and the old/ folder.

class EchemPath

  def initialize(root)
    @root_path = File.expand_path(root)
    @search_dirs = ['.', 'old/']
  end

  # Search the root + search_dirs for the given path. If found, return the
  # full path. Otherwise, throw exception.
  def expand(path)
    @search_dirs.each do |i|
      full_path = File.join(@root_path, i, path)
      if File.exists?(full_path)
        return File.expand_path(full_path) #clean up path
      end
    end

    raise 'Path not found!'
  end
end
