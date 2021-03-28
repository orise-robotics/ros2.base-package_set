# Copyright 2021 Open Rise Robotics Modification
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software

module Autobuild
  def self.colcon(options, &block)
      Colcon.new(options, &block)
  end

  
  # Colcon is not a configurable per say,
  # but it is useful to use its build base
  # structure
  class Colcon < Autobuild::Configurable
    class << self
      def builddir
        @builddir || Configurable.builddir
      end

      def builddir=(new)
        if Pathname.new(new).absolute?
            raise ConfigException, "absolute builddirs are not supported"
        end
        if new.nil? || new.empty?
            raise ConfigException, "builddir must be non-nil and non-empty"
        end

        @builddir = new
      end

      # Whether files that are not within colcon's install manifest but are
      # present in the prefix should be deleted. Note that the contents of
      # {#log_dir} are unaffected.
      #
      # It is false by default.
      def delete_obsolete_files_in_prefix?
          @@delete_obsolete_files_in_prefix
      end

      # Set {#delete_obsolete_files_in_prefix?}
      def delete_obsolete_files_in_prefix=(flag)
          @@delete_obsolete_files_in_prefix = flag
      end

      @@delete_obsolete_files_in_prefix = false


    end
    @builddir = nil
    @importdir = nil
    
    # a key => value association of key arguments for colcon
    attr_reader :keyargs

    @keyargs = Hash.new
    
    # The list of all keys passed to colcon
    def all_keyargs
      additional_keyargs = Hash[
          "--packages-select" => name,
          "--merge-install" => "",
          "--event-handlers" => "console_direct+"]
      keyargs.merge(additional_keyargs).merge(keyargs)
    end

    def self.keyargs
        @keyargs
    end

    def colcon_rc
      File.join(builddir, "colcon_build.rc")
    end

    def configurestamp
      colcon_rc
    end

    def initialize(options)
      @keyargs = Hash.new
      @mutex = Mutex.new
      @importdir = nil
      super(options)
      @delete_obsolete_files_in_prefix = self.class.
          delete_obsolete_files_in_prefix?
      update_srcdir
      setup_tests
    end

    def update_srcdir
      importdir ||= srcdir
      return if File.exist?(File.join(srcdir, 'package.xml'))
      usual_manifestdir = File.join(srcdir, name, 'package.xml')

      if File.exist?(usual_manifestdir)
          srcdir = File.dirname(usual_manifestdir)
          return
      end

      dir_glob = "#{importdir}/**/#{name}/package.xml"
      @srcdir = (Dir[dir_glob].map do |path|
          File.dirname(path)
      end.first || @srcdir)
    end

    def import(options)
      @mutex.synchronize do
          return if updated? || failed?
          result = super(**options)
          update_srcdir
          result
      end
    end

    def setup_tests
      unless test_utility.has_task?
        test_dir = File.join(srcdir, 'test')
        if File.directory?(test_dir)
            test_utility.source_dir = File.join(builddir, 'test_results', name)
        end

        with_tests if test_utility.source_dir
      end
    end


    # (see colcon.delete_obsolete_files_in_prefix?)
    def delete_obsolete_files_in_prefix?
      @delete_obsolete_files_in_prefix
    end

    # (see colcon.delete_obsolete_files_in_prefix=)
    attr_writer :delete_obsolete_files_in_prefix

    def generate_colcon_test_command(verb, colcon_keyargs)
      command = generate_colcon_build_command(verb, colcon_keyargs)
      command
    end
    
    def generate_colcon_build_command(verb, colcon_keyargs)
      command = []
      command << "colcon"
      command << verb
      colcon_keyargs.each do |name, value|
        command << "#{name}"
        command << "#{value}"
      end
      command
    end
    
    def colcon_command(verb, colcon_keyargs, start_msg, done_msg)
      command = generate_colcon_build_command(verb, colcon_keyargs)
      in_dir(Autoproj.root_dir) do
        progress_start start_msg, :done_message => done_msg do
          run('build', *command)
          yield if block_given?
        end
      end
    end

    def build
      colcon_command("build", all_keyargs, "Starting colcon for #{name}", "End colcon for #{name}")
    end

    def with_tests
      command = generate_colcon_test_command("test", all_keyargs)
      test_utility.task do
          progress_start "running tests for %s",
                         done_message: 'tests passed for %s' do
              run('test',
                  command,
                  working_directory: Autoproj.root_dir)
          end
      end
  end


  end

end
