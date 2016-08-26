# This file is licensed under the GNU General Public License v3.0
require 'formula'

class Superlu < Formula
  homepage 'http://crd-legacy.lbl.gov/~xiaoye/SuperLU/'
  url 'http://crd-legacy.lbl.gov/~xiaoye/SuperLU/superlu_4.3.tar.gz'
  sha256 '169920322eb9b9c6a334674231479d04df72440257c17870aaa0139d74416781'

  depends_on 'suite-sparse'

  def patches
    # patch the examples to compile on Mac OS X after installation
    DATA
  end

  def caveats
    <<-EOF.undent
      To run the SuperLU test suite, install 'tmglib' and then run 'make' in
      #{HOMEBREW_PREFIX}/share/doc/superlu/tests
    EOF
  end

  def install
    # parse version number
    major = version.to_s.split('.')[0]
    minor = version.to_s.split('.')[1]
    name = 'superlu'
    
    # don't do stupid things like duplicating older pieces of other
    # libraries into our tree
    system 'cp TESTING/MATGEN/[sdcz]latb4.c TESTING'
    system 'rm -rf TESTING/MATGEN'
    system 'rm SRC/colamd.[ch]'
    inreplace 'SRC/Makefile' do |s|
      s.gsub! 'colamd.o', ''
    end

    # Darwin ar does ranlib automatically as needed
    inreplace 'SRC/Makefile' do |s|
      s.gsub! "\t$(RANLIB) $(SUPERLULIB)", ''
    end

    # these are the prerequisite libraries we need to link; libcolamd
    # should be in /usr/local/lib/ and libblas in /Applications/Xcode.app/
    # Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/
    # MacOSX10.8.sdk/usr/lib/
    deps = %w[-lcolamd -lblas -lsuitesparseconfig]

    # build using the modified Makefile; we only need the library
    # so just build the source directory
    system "make", "-C", "SRC",
                   "CC=#{ENV.cc}",
                   "C_INCLUDE_PATH=-I#{HOMEBREW_PREFIX}/include/suitesparse",
                   "SUPERLULIB=../lib#{name}.a",
                   "BLASLIB=#{deps.join(' ')}"

    # these are the object files that are produced by the above
    objs = Dir.glob 'SRC/*.o'
    hdrs = Dir.glob 'SRC/s*.h'

    # create the dynamic library
    args = %W[ -dynamiclib
               -all_load
               -headerpad_max_install_names
               -install_name \"#{lib}/lib#{name}.#{version}.dylib\"
               -compatibility_version #{major}
               -current_version #{version}
               -o lib#{name}.#{version}.dylib ] + objs + deps
    system ENV.cxx, *args

    # pkg-config file; this is small enough to put inline here
    File::open("#{name}.pc", 'w') do |f|
      f << <<-EOF.undent
        prefix=#{HOMEBREW_PREFIX}
        exec_prefix=${prefix}
        libdir=${exec_prefix}/lib
        includedir=${prefix}/include/superlu

        Name: SuperLU
        Description: Direct solution of large, sparse, nonsymmetric systems of linear equations
        Version: #{version}
        Libs: -L${libdir} -l#{name} #{deps.join(' ')}
        Cflags: -I${includedir}
      EOF
    end

    # fixup examples to be in more sensible names
    system 'mv EXAMPLE examples'
    system 'mv TESTING tests'
    Dir.glob('tests/*.csh').each do |f|
      inreplace f do |s|
        s.gsub! '../EXAMPLE/', '../examples/'
      end
    end
    
    # copy these to their final location
    (include+"#{name}").install *hdrs    
    lib.install "lib#{name}.a"
    lib.install "lib#{name}.#{version}.dylib"
    (lib+"pkgconfig").install "#{name}.pc"
    doc.install 'examples'
    doc.install 'tests'

    # set up version compatibility for the dynamic library
    cd lib do
      ln_s "lib#{name}.#{version}.dylib", "lib#{name}.#{major}.dylib"
      ln_s "lib#{name}.#{version}.dylib", "lib#{name}.dylib"
    end
  end
end

__END__
--- a/EXAMPLE/Makefile
+++ b/EXAMPLE/Makefile
@@ -1,5 +1,3 @@
-include ../make.inc
-
 #######################################################################
 #  This makefile creates the example programs for the linear equation
 #  routines in SuperLU.  The files are grouped as follows:
@@ -32,7 +30,12 @@
 #
 #######################################################################
 
-HEADER   = ../SRC
+HEADER     = HOMEBREW_PREFIX/include/superlu
+LOADER     = $(CC)
+LOADOPTS   =
+SUPERLULIB =
+LIBS       = -LHOMEBREW_PREFIX/lib -lsuperlu -lblas
+CDEFS      = -Wno-implicit-int -Wno-implicit-function-declaration
 
 SLINEXM		= slinsol.o
 SLINEXM1	= slinsol1.o
--- a/TESTING/Makefile
+++ b/TESTING/Makefile
@@ -1,5 +1,3 @@
-include ../make.inc
-
 #######################################################################
 #  This makefile creates the test programs for the linear equation
 #  routines in SuperLU.  The test files are grouped as follows:
@@ -33,7 +31,13 @@
 #
 #######################################################################
 
-HEADER  = ../SRC
+HEADER     = HOMEBREW_PREFIX/include/superlu
+LOADER     = $(CC)
+CDEFS      = -Wno-implicit-int -Wno-implicit-function-declaration
+LOADOPTS   = -LHOMEBREW_PREFIX/lib
+TMGLIB     = slatb4.o dlatb4.o clatb4.o zlatb4.o
+SUPERLULIB =
+BLASLIB    = -lsuperlu -ltmglib -llapack -lblas
 
 ALINTST = sp_ienv.o
 
@@ -45,10 +49,7 @@
 
 ZLINTST = zdrive.o sp_zconvert.o zgst01.o zgst02.o zgst04.o zgst07.o
 
-all: testmat single double complex complex16
-
-testmat:
-	(cd MATGEN; $(MAKE))
+all: single double complex complex16
 
 single: ./stest stest.out
 
--- a/TESTING/MATGEN/slatb4.c
+++ b/TESTING/MATGEN/slatb4.c
@@ -4,7 +4,15 @@
 */
 
 #include <string.h>
-#include "f2c.h"
+typedef int integer;
+typedef unsigned char logical;
+typedef float real;
+typedef double doublereal;
+#define TRUE_ 1
+#define FALSE_ 0
+#include <math.h>
+#define max fmax
+#define abs fabs
 
 /* Table of constant values */
 
--- a/TESTING/MATGEN/dlatb4.c
+++ b/TESTING/MATGEN/dlatb4.c
@@ -4,7 +4,15 @@
 */
 
 #include <string.h>
-#include "f2c.h"
+typedef int integer;
+typedef unsigned char logical;
+typedef float real;
+typedef double doublereal;
+#define TRUE_ 1
+#define FALSE_ 0
+#include <math.h>
+#define max fmax
+#define abs fabs
 
 /* Table of constant values */
 
--- a/TESTING/MATGEN/clatb4.c
+++ b/TESTING/MATGEN/clatb4.c
@@ -4,7 +4,15 @@
 */
 
 #include <string.h>
-#include "f2c.h"
+typedef int integer;
+typedef unsigned char logical;
+typedef float real;
+typedef double doublereal;
+#define TRUE_ 1
+#define FALSE_ 0
+#include <math.h>
+#define max fmax
+#define abs fabs
 
 /* Table of constant values */
 
--- a/TESTING/MATGEN/zlatb4.c
+++ b/TESTING/MATGEN/zlatb4.c
@@ -4,7 +4,15 @@
 */
 
 #include <string.h>
-#include "f2c.h"
+typedef int integer;
+typedef unsigned char logical;
+typedef float real;
+typedef double doublereal;
+#define TRUE_ 1
+#define FALSE_ 0
+#include <math.h>
+#define max fmax
+#define abs fabs
 
 /* Table of constant values */
 
