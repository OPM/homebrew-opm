# This file is licensed under the GNU General Public License v3.0
require 'formula'

class Libf2c < Formula
  homepage 'http://www.netlib.org/f2c/'
  # netlib doesn't provide a versioned link for libf2c itself, so
  # we have to download the entire CLapack and extract it from there
  url 'http://www.netlib.org/clapack/clapack-3.1.1.tgz'
  sha256 'ca47ce8ea907aab6ed7bd01fa4e03a1d14723f99350d7581de0b2153248f1465'
  # encode 0.0.YY.MM.DD as version number when we only have release
  # dates; this is one of the few ways to encode a date into Mach-O
  version '0.0.08.01.07'

  def install
    # we need C compiler
    ENV.cc

    # refer to us by this; this is the name of the header
    name = 'f2c'

    # for some reason this file in needed, but it doesn't have to
    # contain anything. it is easier to create it that the modify
    # the makefile
    system 'touch', 'make.inc'

    # we are not interested in the rest of CLapack, only libf2c
    cd 'F2CLIBS' do
      
      # build these targets in the subdirectory to get the header and
      # the library in the parent
      cd 'libf2c' do
        system 'make', 'hadd'
        system 'make'

        # build the shared library
        objs = Dir.glob '*.o'
  
        # create the dynamic library; undefined dynamic lookup is needed
        # because the runtime will call Fortran _MAIN__
        args = %W[ -dynamiclib
                   -all_load
                   -headerpad_max_install_names
                   -undefined dynamic_lookup
                   -single_module
                   -install_name \"#{lib}/lib#{name}.#{version}.dylib\"
                   -current_version #{version}
                   -o ../lib#{name}.#{version}.dylib ] + objs
        system ENV.cc, *args
      end

      # pkg-config file; this is small enough to put inline here
      File::open("#{name}.pc", 'w') do |f|
        f << <<-EOF.undent
          prefix=#{HOMEBREW_PREFIX}
          exec_prefix=${prefix}
          libdir=${exec_prefix}/lib
          includedir=${prefix}/include

          Name: libf2c
          Description: Fortran-to-C compiler runtime library
          Version: #{version}
          Libs: -L${libdir} -l#{name}
          Cflags: -I${includedir}
        EOF
      end
      (lib+"pkgconfig").install "#{name}.pc"

      # for some reason the header file is NOT copied to the parent,
      # so there's an old, stale on there
      include.install "libf2c/#{name}.h"

      # copy libraries due lack of install target in makefile
      lib.install "lib#{name}.a"
      lib.install "lib#{name}.#{version}.dylib"

      # set up version compatibility for the dynamic library
      cd lib do
        ln_s "lib#{name}.#{version}.dylib", "lib#{name}.dylib"
      end
    end
  end

  def test
    # test program written in pure C (since this is only the runtime
    # library; we don't install the compiler itself)
    # this is a classic "Hello, World!" program translated from Fortran
    File::open("hello.c", "w") do |f|
      f << <<-EOF.undent
        #include "f2c.h"

        integer s_wsle(cilist *);
        integer do_lio(integer *, integer *, char *, ftnlen);
        integer e_wsle(void);

        int main (void) {
          integer one = 1;
          integer nine = 9;
          cilist io = {0, 6, 0, 0, 0};
          s_wsle (&io);
          do_lio (&nine, &one, "Hello, World!", (ftnlen) 13);
          e_wsle ();
          return 0;
        }
      EOF
      system ENV.cc, 'hello.c', '-lf2c', '-o hello'
    end
  end
end
