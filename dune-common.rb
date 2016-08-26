# This file is licensed under the GNU General Public License v3.0
require 'formula'

class DuneCommon < Formula
  homepage 'http://www.dune-project.org/'
  url 'http://www.dune-project.org/download/2.2.1/dune-common-2.2.1.tar.gz'
  sha256 '6b16b2390af79e2ca93367c95d06ed536b58422034cf34e4437fc6201bb1ab85'

  depends_on 'autoconf'  => :build
  depends_on 'automake'  => :build
  depends_on 'libtool'   => :build
  depends_on 'pkgconfig' => :build

  # use Apple's Accelerate framework instead
  #depends_on 'openblas'
  depends_on 'gmp'
  depends_on 'metis4'
  depends_on 'superlu'
  option 'mpi', 'Enable MPI support'
  depends_on MPIDependency.new(:cc, :cxx, :f90) if build.with? "mpi"
  option 'with-c++11' if MacOS.version >= :lion

  # if we are built with c++11, make sure we link to a boost that is
  depends_on 'boost' => ('--with-c++11' if build.with? 'c++11')

  def patches
	# am is a directory that is linked not a file; this bug seems to only be
	# triggered when we are building in a temporary and refering to the Cellar
    system 'sed', '-i', '', 's/rm -f am/rm -rf am/g', 'bin/dune-autogen'

    # this cause a compiler warning in our client code
    system 'sed', '-i', '', 's/friend struct std::numeric_limits/friend class std::numeric_limits/', 'dune/common/bigunsignedint.hh'
  end

  def install
    ENV.fortran

    # if we are NOT built with c++11, make sure we don't link to a boost that is
    if (not build.with? 'c++11') and Tab.for_formula('boost').with?('c++11') then
      raise Homebrew::InstallationError.new(self, "boost built --with-c++11 but this package is not")
    end	  

    # parse version number
    major = version.to_s.split('.')[0]
    minor = version.to_s.split('.')[1]

    # parse name
    suite = name.to_s.split('-')[0]
    modul = name.to_s.split('-')[1]

    # upgrade from pre-release -std=c++0x to official -std=c++11
    system 'sed', '-i', '', 's/-std=c++0x/-std=c++11/g', 'm4/cxx0x_compiler.m4'

    # add version number to the generated library
    File::open("lib/Makefile.am", 'a') do |f|
      f << <<-EOF.undent
        lib#{suite}#{modul}_la_LDFLAGS = -version-info #{major}:#{minor}:0
      EOF
    end

	# avoid getting into a conflict with version in the Cellar
	ENV.append 'DUNE_CONTROL_PATH', "#{HOMEBREW_PREFIX}"

    # generate configuration files (since we modified build-system)
    system 'touch', 'stamp-vc'
	system 'bin/dunecontrol', '--current', 'autogen'

    # remove the misguided idea that the major number should always be increased
    # to avoid having zero in that position
    system 'sed', '-i', '.bak', '/func_arith \$current + 1/d', 'ltmain.sh'

    # add minor version to compatibility_version to make it only compatible with itself
    system 'sed', '-i', '.bak',
      's/\(-compatibility_version\ \(\${wl}\)*\$minor_current\)/\1\.\$revision/', 'ltmain.sh'

    # there is a test which includes stdlib.h, which apparently needs
    # this define if we are using clang
    if build.with? 'mpi' and ENV.compiler == :clang
	  ENV.append 'CXXFLAGS', ' -D_WCHAR_T'
    end

    args = %W[ --enable-fieldvector-size-is-method
               --enable-shared
               --prefix=#{prefix}
             ]
    args << "--enable-parallel" if build.with? 'mpi'

	# use C++11 runtime library
    if MacOS.version >= :lion and build.with? 'c++11'
	  if ENV.compiler == :clang
		ENV.append 'CXX', ' -stdlib=libc++'
	  end
	else
	  args << "--disable-gxx0xcheck"
    end
  
    system 'bin/dunecontrol', "--configure-opts=#{args.join(' ')}", '--current', 'configure'

    # compile and copy target files to their final location
    system 'make', 'install'

    # rearrange so that we get the correct symlink
    cd lib do
      mv "lib#{suite}#{modul}.#{major}.dylib", "lib#{suite}#{modul}.#{version}.dylib"
      rm_f "lib#{suite}#{modul}.#{major}.#{minor}.dylib"
      ln_s "lib#{suite}#{modul}.#{version}.dylib", "lib#{suite}#{modul}.#{major}.#{minor}.dylib"
      rm_f "lib#{suite}#{modul}.#{major}.dylib"
      ln_s "lib#{suite}#{modul}.#{major}.#{minor}.dylib", "lib#{suite}#{modul}.#{major}.dylib"
      rm_f "lib#{suite}#{modul}.dylib"
      ln_s "lib#{suite}#{modul}.#{major}.dylib", "lib#{suite}#{modul}.dylib"
    end
  end
end
