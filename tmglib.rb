# This file is licensed under the GNU General Public License v3.0
require 'formula'

class Tmglib < Formula
  homepage 'http://www.netlib.org/lapack/'
  url 'http://www.netlib.org/lapack/lapack-3.4.2.tgz'
  sha1 '93a6e4e6639aaf00571d53a580ddc415416e868b'

  def install
    # we need Fortran to compile
    ENV.fortran
    
    # parse version number
    major = version.to_s.split('.')[0]
    minor = version.to_s.split('.')[1]
    name = 'tmglib'
    
    inreplace 'TESTING/MATGEN/Makefile' do |s|
      # we'll rather define necessary macros on the command line
      s.gsub! 'include ../../make.inc', ''

      # Darwin ar does ranlib automatically as needed
      s.gsub! "\t$(RANLIB) $@", ''
      s.gsub! "\t$(RANLIB) ../../$(TMGLIB)", ''      
    end

    # these are the prerequisite library we need to link; they
    # should be in /Applications/Xcode.app/Contents/Developer/Platforms/
    # MacOSX.platform/Developer/SDKs/MacOSX10.8.sdk/usr/lib/
    deps = %w[-llapack -lblas]

    # build using the modified Makefile; we only need the library
    # so just build the source directory
    system "make", "-C", "TESTING/MATGEN",
                   "FORTRAN=#{ENV.fc}",
                   "NOOPT=-O0",
                   "ARCH=ar",
                   "ARCHFLAGS=cr",
                   "TMGLIB=lib#{name}.a"

    # these are the object files that are produced by the above
    objs = Dir.glob 'TESTING/MATGEN/*.o'

    # create the dynamic library
    args = %W[ -dynamiclib
               -all_load
               -headerpad_max_install_names
               -install_name \"#{lib}/lib#{name}.#{version}.dylib\"
               -compatibility_version #{major}
               -current_version #{version}
               -o lib#{name}.#{version}.dylib ] + objs + deps
    system ENV.cc, *args

    # pkg-config file; this is small enough to put inline here
    File::open("#{name}.pc", 'w') do |f|
      f << <<-EOF.undent
        prefix=#{HOMEBREW_PREFIX}
        exec_prefix=${prefix}
        libdir=${exec_prefix}/lib
        includedir=${prefix}/include

        Name: TMGLib
        Description: Test Matrix Generator library for LAPACK
        Version: #{version}
        Libs: -L${libdir} -l#{name} #{deps.join(' ')}
        Cflags: -I${includedir}
      EOF
    end

    # copy libraries due lack of install target in makefile
    lib.install "lib#{name}.a"
    lib.install "lib#{name}.#{version}.dylib"
    (lib+"pkgconfig").install "#{name}.pc"

    # set up version compatibility for the dynamic library
    cd lib do
      ln_s "lib#{name}.#{version}.dylib", "lib#{name}.#{major}.dylib"
      ln_s "lib#{name}.#{version}.dylib", "lib#{name}.dylib"
    end
  end
end
