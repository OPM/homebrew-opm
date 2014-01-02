# This file is licensed under the GNU General Public License version 3
require 'formula'

class Cjson < Formula
  homepage 'http://sourceforge.net/projects/cjson/'
  url      'http://downloads.sourceforge.net/project/cjson/cJSONFiles.zip'
  sha1     '3a016bc2b75a2eafa5f9ad192b0154a9fa2b2abe'
  version  '20130819'

  def install
    name = "cJSON"

    # linker wants something that looks like a valid version number,
    # but all we have is a date; we approximate by using 0.yy.mm
    major = version.to_s[2...4]
    minor = version.to_s[4...6]
    micro = version.to_s[6...8]

    # there is a _MACOSX directory which prevents us from shifting into
    # the right directory automatically after unpacking
    cd "#{name}"
    
    # compile
    system ENV.cc, '-c', "#{name}.c"

    # create the static library
    system 'ar', 'r', "lib#{name.downcase}.a", "#{name}.o"
    system 'ranlib', "lib#{name.downcase}.a"

    # create the dynamic library
    args = %W[ -dynamiclib
               -all_load
               -headerpad_max_install_names
               -install_name \"#{lib}/lib#{name.downcase}.#{version}.dylib\"
               -current_version 0.#{major}.#{minor}
               -o lib#{name.downcase}.#{version}.dylib
               #{name}.o ]
    system ENV.cc, *args

    # pkg-config file; this is small enough to put inline here
    File::open("#{name.downcase}.pc", 'w') do |f|
      f << <<-EOF.undent
        prefix=#{HOMEBREW_PREFIX}
        exec_prefix=${prefix}
        libdir=${exec_prefix}/lib
        includedir=${prefix}/include

        Name: cJSON
        Description: Ultra-lightweight, portable, single-file, simple-as-can-be ANSI-C compliant JSON parser
        Version: #{version}
        Libs: -L${libdir} -l#{name.downcase}
        Cflags: -I${includedir}
      EOF
    end

    # copy these to their final location
    include.install "#{name}.h"
    
    lib.install "lib#{name.downcase}.a"
    lib.install "lib#{name.downcase}.#{version}.dylib"
    (lib+"pkgconfig").install "#{name.downcase}.pc"

    # set up version compatibility for the dynamic library
    cd lib do
      ln_s "lib#{name.downcase}.#{version}.dylib", "lib#{name.downcase}.dylib"
    end
  end   
end
