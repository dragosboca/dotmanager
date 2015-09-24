require 'singleton'

class Hash
  def self.deep_symbolize(value)
    return value unless value.is_a?(Hash)
    hash = value.inject({}) { |memo, (k, v)| memo[k.to_sym] = Hash.deep_symbolize(v); memo }
    hash
  end
end

module Dotfiles
  class Config
    include Singleton

    def initialize
      @files  = []
      @config = {}
    end

    def load_file(filename)
      unless @files.include? filename
        @files << filename
        data   = Hash.deep_symbolize YAML.load_file(filename) # transform the keys in symbols
        merger = proc { |_, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
        @config.merge! data, &merger
      end if File.exist?(Util.abspath(filename))
      @files.include? filename
    end

    def [](key)
      @config[key]
    end

    def source_defined?(source)
      !@config[:symlinks].find { |pair| pair.split(',')[0].trim == source }.nil?
    end

    def destination_defined?(destination)
      !@config[:symlinks].find { |pair| pair.split(',')[1].trim == destination }.nil?
    end

    def get_destination(source)
      @config[:symlinks].find { |pair| pair.split(',')[0].trim == source }.split(',')[1].trim
    end

    def get_source(destination)
      @config[:symlinks].find { |pair| pair.split(',')[1].trim == destination }.split(',')[0].trim
    end
  end
end
