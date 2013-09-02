# This file is licensed under the GNU General Public License v3.0
require 'formula'

class Alberta < Formula
  homepage 'http://numerik.mi.fu-berlin.de/dune/psurface/index.php'
  url 'http://www.alberta-fem.de/Downloads/alberta-2.0.1.tar.gz'
  sha1 '8052e0e4567438b43167d2f471528e7f8e03766b'

  depends_on 'autoconf' => :build
  depends_on 'automake' => :build
  depends_on 'libtool'  => :build
  depends_on :x11

  def patch
    # parse version number
    major = version.to_s.split('.')[0]
    minor = version.to_s.split('.')[1]
    name = 'alberta'

    # add version number to the generated library
    File::open("alberta_util/src/Makefile.am", 'a') do |f|
      f << <<-EOF.undent
        libalberta_util_la_LDFLAGS = -version-info #{major}:#{minor}:0
        libalberta_util_debug_la_LDFLAGS = -version-info #{major}:#{minor}:0
      EOF
    end
    File::open("alberta/src/alberta_1d/Makefile.am", 'a') do |f|
      f << <<-EOF.undent
        libalberta_1d_la_LDFLAGS = -version-info #{major}:#{minor}:0
        libalberta_1d_debug_la_LDFLAGS = -version-info #{major}:#{minor}:0
      EOF
    end
    File::open("alberta/src/alberta_2d/Makefile.am", 'a') do |f|
      f << <<-EOF.undent
        libalberta_2d_la_LDFLAGS = -version-info #{major}:#{minor}:0
        libalberta_2d_debug_la_LDFLAGS = -version-info #{major}:#{minor}:0
      EOF
    end
    File::open("alberta/src/alberta_3d/Makefile.am", 'a') do |f|
      f << <<-EOF.undent
        libalberta_3d_la_LDFLAGS = -version-info #{major}:#{minor}:0
        libalberta_3d_debug_la_LDFLAGS = -version-info #{major}:#{minor}:0
      EOF
    end
  end    

  def install
	ENV.fortran
    system './configure', "--prefix=#{prefix}"

    # remove the misguided idea that the major number should always be increased
    # to avoid having zero in that position
    system 'sed', '-i', '.bak', '/func_arith \$current + 1/d', 'libtool'    

    # copy the built files into their target directories
    system 'make', 'install'
  end
end
