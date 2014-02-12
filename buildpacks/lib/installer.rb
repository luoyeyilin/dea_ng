require "open3"
require "dea/utils/platform_compat"

module Buildpacks
  class Installer < Struct.new(:path, :app_dir, :cache_dir)
    abstract_method :command
    include_platform_compat

    def detect
      @detect_output, status = Open3.capture2 command('detect')
      status == 0
    rescue => e
      puts "Failed to run buildpack detection script with error: #{e}"
      false
    end

    def name
      @detect_output ? @detect_output.strip : nil
    end

    def compile
      ok = system "#{command('compile')} #{cache_dir}"
      raise "Buildpack compilation step failed:\n" unless ok
    end

    def release_info
      output, status = Open3.capture2 command("release")
      raise "Release info failed:\n#{output}" unless status == 0
      YAML.load(output)
    end
  end

  class LinuxInstaller < Installer
    def command(command_name)
      "#{path}/bin/#{command_name} #{app_dir}"
    end
  end

  class WindowsInstaller < Installer
    def command(command_name)
      "ruby #{path}/bin/#{command_name} #{app_dir}"
    end
  end
end