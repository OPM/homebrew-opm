# This file is licensed under the GNU General Public License v3.0
require 'formula'

class DuneIstl < Formula
  homepage 'http://www.dune-project.org/'
  url 'http://www.dune-project.org/download/2.2.1/dune-istl-2.2.1.tar.gz'
  sha1 'e213d2daa5c5f330d397e7951544170151042f8d'

  depends_on 'autoconf'  => :build
  depends_on 'automake'  => :build
  depends_on 'libtool'   => :build
  depends_on 'pkgconfig' => :build

  # these options are there for compatibility with dune-common
  option 'mpi', 'Enable MPI support'
  option 'with-c++11' if MacOS.version >= :lion

  depends_on 'dune-common'
  depends_on 'superlu'
	
  def install
    # parse version number
    major = version.to_s.split('.')[0]
    minor = version.to_s.split('.')[1]

    # parse name
    suite = name.to_s.split('-')[0]
    modul = name.to_s.split('-')[1]

	# avoid getting into a conflict with version in the Cellar
	ENV.append 'DUNE_CONTROL_PATH', "#{HOMEBREW_PREFIX}"

    # generate configuration files (since we modified build-system)
    system 'touch', 'stamp-vc'
	system "#{HOMEBREW_PREFIX}/bin/dunecontrol", '--current', 'autogen'

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
  
    system "#{HOMEBREW_PREFIX}/bin/dunecontrol", "--configure-opts=#{args.join(' ')}", '--current', 'configure'

    # compile and copy target files to their final location
    system 'make', 'install'
  end
end
