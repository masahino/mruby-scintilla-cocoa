MRuby::Gem::Specification.new('mruby-scintilla-cocoa') do |spec|
  spec.license = 'MIT'
  spec.authors = 'masahino'
  spec.version = '5.6.7'

  raise 'mruby-scintilla-cocoa supports macOS only' unless RUBY_PLATFORM.include?('darwin')

  spec.add_dependency 'mruby-scintilla-base',
                      github: 'masahino/mruby-scintilla-base'

  require 'open-uri'
  require 'shellwords'

  scintilla_version = '567'
  archive_url = "https://www.scintilla.org/scintilla#{scintilla_version}.tgz"
  source_root = "#{build_dir}/scintilla"
  source_dir = "#{source_root}/scintilla"
  cocoa_dir = "#{source_dir}/cocoa"
  header = "#{cocoa_dir}/ScintillaView.h"
  framework_dir = "#{build_dir}/framework"
  framework = "#{framework_dir}/Release/Scintilla.framework"

  file header do
    URI.open(archive_url, open_timeout: 10, read_timeout: 30) do |archive|
      FileUtils.mkdir_p(source_root)
      IO.popen("tar xfz - -C #{filename source_root}", 'wb') do |tar|
        tar.write(archive.read)
      end
      raise "tar failed: #{archive_url} (#{$?.exitstatus})" unless $?.success?
    end
    raise "#{header} not produced" unless File.exist?(header)
  end

  file framework => header do
    sh [
      'xcodebuild',
      '-project', "#{cocoa_dir}/Scintilla/Scintilla.xcodeproj",
      '-scheme', 'Scintilla',
      '-configuration', 'Release',
      "SYMROOT=#{framework_dir}",
      'build'
    ].map { |part| Shellwords.escape(part) }.join(' ')
  end

  task :mruby_scintilla_cocoa_compile_option do
    # mruby-scintilla-base is only registered once dependency resolution has
    # run, so this lookup has to be deferred to task time.
    linker.flags_before_libraries << build.gems['mruby-scintilla-base'].lexilla_archive
    [cc, cxx, objc, mruby.cc, mruby.cxx, mruby.objc].each do |compiler|
      compiler.include_paths << "#{source_dir}/include"
      compiler.include_paths << cocoa_dir
    end
  end

  file "#{dir}/src/scintilla-cocoa.m" => [
    :mruby_scintilla_cocoa_compile_option,
    framework
  ]

  linker.flags_before_libraries << "-F#{framework_dir}/Release"
  linker.flags_before_libraries << '-framework Scintilla'
  linker.flags_before_libraries << '-framework Cocoa'
  linker.flags_before_libraries << '-Wl,-rpath,@executable_path/../Frameworks'
  linker.flags_before_libraries << "-Wl,-rpath,#{framework_dir}/Release"
end
