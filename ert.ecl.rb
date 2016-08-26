# This file is licensed under the GNU General Public License v3.0
require 'formula'

class ErtEcl < Formula
  homepage 'http://github.com/Ensembles/ert'  
  url 'https://github.com/Ensembles/ert/archive/30f5071bd3bf2d55b8ad0a800768eec43f976bf8.tar.gz'
  sha256 '2d39bd6b33b012ab581c71d3cb05e0eadc9abea0a8324d39c3553bdd2f8618dc'
  version '1.0'

  depends_on 'cmake' => :build

  def install
    system "cmake", "devel", *std_cmake_args
    system "make", "install"
  end
end
