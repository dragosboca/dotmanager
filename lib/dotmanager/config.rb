require 'singleton'
require 'yaml'
require 'dotmanager/util'

# from https://gist.github.com/morhekil/998709/aafd65c5780a2ce3cda3ef020b6e5dead7cef1d0
# Symbolizes all of hash's keys and subkeys.
# Also allows for custom pre-processing of keys (e.g. downcasing, etc)
# if the block is given:
#
# somehash.deep_symbolize { |key| key.downcase }
#
# Usage: either include it into global Hash class to make it available to
#        to all hashes, or extend only your own hash objects with this
#        module.
#        E.g.:
#        1) class Hash; include DeepSymbolizable; end
#        2) myhash.extend DeepSymbolizable

module DeepSymbolizable
   def deep_symbolize(&block)
      method = self.class.to_s.downcase.to_sym
      syms = DeepSymbolizable::Symbolizers
      syms.respond_to?(method) ? syms.send(method, self, &block) : self
   end

   module Symbolizers
      extend self

      # the primary method - symbolizes keys of the given hash,
      # preprocessing them with a block if one was given, and recursively
      # going into all nested enumerables
      def hash(hash, &block)
         hash.inject({}) do |result, (key, value)|
            # Recursively deep-symbolize subhashes
            value = _recurse_(value, &block)

            # Pre-process the key with a block if it was given
            key = yield key if block_given?
            # Symbolize the key string if it responds to to_sym
            sym_key = key.to_sym rescue key
            # write it back into the result and return the updated hash
            result[sym_key] = value
            result
         end
      end

      # walking over arrays and symbolizing all nested elements
      def array(ary, &block)
         ary.map { |v| _recurse_(v, &block) }
      end

      # handling recursion - any Enumerable elements (except String)
      # is being extended with the module, and then symbolized
      def _recurse_(value, &block)
         if value.is_a?(Enumerable) && !value.is_a?(String)
            # support for a use case without extended core Hash
            value.extend DeepSymbolizable unless value.class.include?(DeepSymbolizable)
            value = value.deep_symbolize(&block)
         end
         value
      end
   end
end

module Dotmanager
   class Config
      attr_reader :files
      include Singleton
      
      def initialize
         @files  = []
         @config = {}
         @config.extend DeepSymbolizable
      end

      # noinspection RubyScope
      def load_file(filename)
         file = Util.abspath(filename)
         unless @files.include? file
            @files << file
            data   = YAML.load_file(file) # transform the keys in symbols
            merger = proc { |_, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
            @config.merge! data, &merger
            @config = @config.deep_symbolize
         end if File.exist?(file)
         @files.include? file
      end

      def [](key)
         @config[key]
      end

      def source_defined?(source)
         !@config[:symlinks].find { |s| s[:source] == source }.nil?
      end

      def destination_defined?(destination)
         !@config[:symlinks].find { |s| s[:destination] == destination }.nil?
      end

      def get_destination(source)
         fail "Undefined source: #{source}" unless source_defined? source
         (@config[:symlinks].find { |s| s[:source] == source })[:destination].strip
      end

      def get_source(destination)
         fail "Undefined destination: #{destination}" unless destination_defined? destination
         (@config[:symlinks].find { |s| s[:destination] == destination })[:source].strip
      end

      def add_symlink(source, destination, description)
         @config[:symlinks] << { description: description, source: source, destination: destination }
      end

      def delete_source_symlink(source)
         fail "Undefined source: #{source}" unless source_defined? source
         @config[:symlinks].reject! { |s| s[:source] == source }
      end

      def delete_destination_symlink(destination)
         fail "Undefined destination: #{destination}" unless destination_defined? destination
         @config[:symlinks].reject! { |s| s[:destination] == destination }
      end

      def repo_defined?(repo)
         !config[:git_repos].find { |r| r[:repo] == repo }.nil?
      end

      def get_repo_dest(repo)
         fail "Undefined repo #{repo}" unless repo_defined? repo
         (@config[:git_repos].find {|r| r[:repo] == repo})[:dest]
      end

      def save_database

      end
   end
end
