require 'fileutils'

module Dotmanager
  module Util
    extend self

    def abspath(source)
      File.expand_path source
    end
  end
end
