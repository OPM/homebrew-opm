# This file is licensed under the GNU General Public License v3.0
require 'formula'

class Tinyxml < Formula
  homepage 'http://grinninglizard.com/tinyxml/'
  url      'http://downloads.sf.net/project/tinyxml/tinyxml/2.6.2/tinyxml_2_6_2.zip'
  sha256   'ac6bb9501c6f50cc922d22f26b02fab168db47521be5e845b83d3451a3e1d512'

  option 'with-c++11' if MacOS.version >= :lion

  def patches
    # make it so it always compile with STL (like on Debian)
    DATA
  end

  def install
    # parse version number
    major = version.to_s.split('.')[0]
    minor = version.to_s.split('.')[1]
    name = 'tinyxml'

    # remove GNU toolchain specific compiler settings
    inreplace 'Makefile' do |s|
      #s.remove_make_var! 'CXX'
      #s.remove_make_var! 'LD'
      s.gsub! /^CXX\ *:=.*$/, 'CXX:=$(CXX) -fno-common'
      s.gsub! /^LD\ *:=.*$/, 'LD:=$(CXX)'
      s.gsub! /^TINYXML_USE_STL\ *:=.*$/, 'TINYXML_USE_STL:=YES'
    end

    # use C++11 runtime library
    if MacOS.version >= :lion and build.with? 'c++11'
      stdcxx = '-std=c++11'
      stdlib = '-stdlib=libc++'
    end

    # compile all source units by making the example program
    system 'make', "CXXFLAGS=#{stdcxx} #{stdlib} #{ENV.cxxflags}",
                   "LDFLAGS=#{stdlib} #{ENV.ldflags}"

    # these are the object files that are produced by the above
    objs = Dir.glob 'tiny*.o'

    # create the static library    
    system 'ar', 'r', "lib#{name}.a", *objs
    system 'ranlib', "lib#{name}.a"

    # create the dynamic library
    args = %W[ -dynamiclib
               -all_load
               -headerpad_max_install_names
               -install_name \"#{lib}/lib#{name}.#{version}.dylib\"
               -compatibility_version #{major}
               -current_version #{version}
               -o lib#{name}.#{version}.dylib ] + objs
    system ENV.cxx, stdlib, *args

    # pkg-config file; this is small enough to put inline here
    File::open("#{name}.pc", 'w') do |f|
      f << <<-EOF.undent
        prefix=#{HOMEBREW_PREFIX}
        exec_prefix=${prefix}
        libdir=${exec_prefix}/lib
        includedir=${prefix}/include

        Name: TinyXml
        Description: Simple, small, C++ XML parser
        Version: #{version}
        Libs: -L${libdir} -l#{name}
        Cflags: -I${includedir}
      EOF
    end

    # copy these to their final location
    include.install "#{name}.h"
    #include.install "tinystr.h"
    lib.install "lib#{name}.a"
    lib.install "lib#{name}.#{version}.dylib"
    (lib+"pkgconfig").install "#{name}.pc"
    doc.install (Dir.glob 'docs/*')

    # set up version compatibility for the dynamic library
    cd lib do
      ln_s "lib#{name}.#{version}.dylib", "lib#{name}.#{major}.#{minor}.dylib"
      ln_s "lib#{name}.#{version}.dylib", "lib#{name}.#{major}.dylib"
      ln_s "lib#{name}.#{version}.dylib", "lib#{name}.dylib"
    end
  end
end

__END__
--- a/tinyxml.h
+++ b/tinyxml.h
@@ -26,6 +26,10 @@
 #ifndef TINYXML_INCLUDED
 #define TINYXML_INCLUDED
 
+#ifndef TIXML_USE_STL
+#define TIXML_USE_STL
+#endif
+
 #ifdef _MSC_VER
 #pragma warning( push )
 #pragma warning( disable : 4530 )
--- a/xmltest.cpp
+++ b/xmltest.cpp
@@ -2,7 +2,7 @@
    Test program for TinyXML.
 */
 
-
+#define TIXML_USE_STL
 #ifdef TIXML_USE_STL
 	#include <iostream>
 	#include <sstream>
