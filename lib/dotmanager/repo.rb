require 'dotmanager/config'
require 'dotmanager/util'
require 'git'

module Dotmanager
   class Repo
      extend self

      def add_file(filename)
         config = Config.instance
         repobase = config[:base_repo]
         g = Git.open repobase, :log => (Logger.new STDOUT)
         g.add filename # add the file
         config.files.each do |dbfile|
            g.add dbfile
         end # also add the database in the same commit
         g.commit "add #{filename} to the database"
      end
      
      def remove_file(filename)
         config = Config.instance
         repobase = config[:base_repo]
         g = Git.open repobase, :log => (Logger.new STDOUT)
         g.remove filename # add the file
         config.files.each do |dbfile|
            g.add dbfile
         end # also add the database in the same commit
         g.commit "remove #{filename} from the database"
      end
      
   end
end
