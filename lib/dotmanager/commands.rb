require 'yaml' # for the config file
require 'git'
require 'fileutils' # mv, ln, cp,...
require 'dotmanager/config'
require 'dotmanager/util'
require 'dotmanager/repo'

module Dotmanager
  class Action
    # create a new symlink, add the symlink to the database and add the new file to git repo
    def create_symlink(source, destination, **options)
      config = Config.instance
      fail "Unexistent source file: #{source}" unless FileUtil.stat(source).file?
      fail "File: #{source} or #{destination} already in database" if Config.source_defined?(source) || Config.destination_defined?(destination)
      begin
        FileUtil.ln_s Util.abspath(source), Util.abspath(destination)
      rescue Errno::EEXIST
        raise 'Destination file already in the repo. Maybe you should use install or force'
      end
      # now if the symlink suceeded
      config.add_symlink(source, destination, options[:description] rescue "No description")
      Repo.add_file(destination)
      config.save_database
    end

    def delete_existing_symlink(source, **options)
      config = Config.instance
      fail "The file: #{source} is not in the database" unless Config.source_defined? Util.abspath(source)
      fail "The file: #{source} is registered in the database but is not a symlink." unless File.stat(source).symlink?
      destination = config.get_destination source
      FileUtil.rm Util.abspath(source)
      FileUtil.mv Util.abspath(destination), Util.abspath(source)
      if options[:remove_from_git] # also update the db
        Repo.remove_file Config.get_destination(source)
        config.remove_source source # we must do
      end
      config.remove_source source if options[:update_db]
    end

    def install_existing_symlink(source, **_options)
      config = Config.instance
      fail "Undefined source: #{source}" unless config.source_defined? source
      destination = Config.get_destination(source)
      if FileUtil.stat(Util.abspath source).file?
        puts "#{source} already exists. Creating backup"
        backup_file source
      end
      FileUtil.symlink Util.abspath(source), Util.abspath(destination)
    end

    def check_symlink(source)
      config = Dotmanager::Config.instance
      return unless config.source_defined? source
      def_source = Util.abspath config.get_destination source
      def_destination = Util.abspath config.get_destination def_source
      File.readlink(def_source) == def_destination
    end

    def check_all_symlinks
    end

    def install_all_symlinks # This is part of bootstrap process (if ever run)
    end

    def clone_repo(_repo)
    end

    def install_package(_package)
    end

    def uninstall_package(_package)
    end

    def install_all_packages
    end

    def install_fonts
    end

    private

    def download_file(_url, _dest)
    end

    def backup_file(filename)
      FileUtil.mv(Util.abspath(filename), Util.abspath("#{filename}.dotbackup"))
    end
  end

  class Process
    def bootstrap
    end

    def new_env
    end
  end
end
