require 'formula'

class OpmCore < Formula
  homepage 'http://www.opm-project.org/'
  url      'https://github.com/OPM/opm-core.git', :tag => 'release/2013.10/final'
  head     'https://github.com/OPM/opm-core.git', :branch => 'master'
  version  '1.1'  # must set version here to get correct dir name
  
  # if we are built with c++11, make sure we link to a boost that is
  option 'with-c++11' if MacOS.version >= :lion

  depends_on 'cmake'     => :build
  depends_on 'boost'     => ('--with-c++11' if build.with? 'c++11')
  depends_on 'dune-istl' => [:recommended, ('--with-c++11' if build.with? 'c++11')]
 # use Apple's Accelerate framework instead
  #depends_on 'openblas'
  #depends_on 'lapack'
  depends_on 'suite-sparse' => :optional
  depends_on 'superlu'      => :optional
  depends_on 'tinyxml'      => [:optional, ('--with-c++11' if build.with? 'c++11')]
  depends_on 'ert'          => :optional

  # disable SuperENV, our configuration scripts will find OK options itself
  env :std
  
  def install
    # get the version number from dune.module
    #version = %x[sed -n 's/Version *: *\(.*\)/\1/p' dune.module]
    
    # if we are NOT built with c++11, make sure we don't link to a boost that is
    if (not build.with? 'c++11') and Tab.for_formula('boost').with?('c++11') then
      raise Homebrew::InstallationError.new(self, "boost built --with-c++11 but this package is not")
    end	  

	# use C++11 runtime library
    if MacOS.version >= :lion and build.with? 'c++11'
	  if ENV.compiler == :clang
		ENV.append 'CXX', ' -stdlib=libc++'
	  end
    end

    # configuration options
    args = %W[-DCMAKE_INSTALL_PREFIX=#{prefix}
              -DBUILD_SHARED_LIBS=ON
              -DCMAKE_BUILD_TYPE=Release
              -DWHOLE_PROG_OPTIM=ON
              -DUSE_RUNPATH=OFF
              -DBUILD_TESTING=OFF
              -DBUILD_EXAMPLES=OFF]

    # compile and copy target files to their final location
    system "cmake", ".", *args
    system "make install"
  end
end
