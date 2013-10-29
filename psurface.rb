# This file is licensed under the GNU General Public License v3.0
require 'formula'

class Psurface < Formula
  homepage 'http://numerik.mi.fu-berlin.de/dune/psurface/index.php'
  url 'http://numerik.mi.fu-berlin.de/dune/psurface/libpsurface-1.3.1.tar.gz'
  sha1 '713ee4b9ea478671e693f2bf69675f14d44a749f'

  depends_on 'autoconf' => :build
  depends_on 'automake' => :build
  depends_on 'libtool'  => :build

  def patches
    # parse version number
    major = version.to_s.split('.')[0]
    minor = version.to_s.split('.')[1]

    # add version number to the generated library
    File::open("src/Makefile.am", 'a') do |f|
      f << <<-EOF.undent
        lib#{name}_la_LDFLAGS = -version-info #{major}:#{minor}:0
      EOF
    end

	{ :p0 => [] }
  end    

  def install
    # generate platform-specific probe code
    system 'autoreconf', '-isf'
    system './configure', "--prefix=#{prefix}"
    
    # remove the misguided idea that the major number should always be increased
    # to avoid having zero in that position
    system 'sed', '-i', '.bak', '/func_arith \$current + 1/d', 'libtool'    

    # add minor version to compatibility_version to make it only compatible with itself
    system 'sed', '-i', '.bak',
      's/\(-compatibility_version\ \(\${wl}\)*\$minor_current\)/\1\.\$revision/', 'libtool'

    # copy the built files into their target directories
    system 'make', 'install'

    # parse version number
    major = version.to_s.split('.')[0]
    minor = version.to_s.split('.')[1]

    # rearrange so that we get the correct symlink
    cd lib do
      mv "lib#{name}.#{major}.dylib", "lib#{name}.#{version}.dylib"
      rm_f "lib#{name}.#{major}.#{minor}.dylib"
      ln_s "lib#{name}.#{version}.dylib", "lib#{name}.#{major}.#{minor}.dylib"
      rm_f "lib#{name}.#{major}.dylib"
      ln_s "lib#{name}.#{major}.#{minor}.dylib", "lib#{name}.#{major}.dylib"
      rm_f "lib#{name}.dylib"
      ln_s "lib#{name}.#{major}.dylib", "lib#{name}.dylib"
    end
  end
end
