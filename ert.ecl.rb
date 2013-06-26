# This file is licensed under the GNU General Public License v3.0
require 'formula'

class ErtEcl < Formula
  homepage 'http://github.com/Ensembles/ert'  
  url 'https://github.com/Ensembles/ert/archive/30f5071bd3bf2d55b8ad0a800768eec43f976bf8.tar.gz'
  sha1 '97497b060978e8b368770eb0fb106f9080b651d7'
  version '1.0'

  depends_on 'cmake' => :build

  def install
    system "cmake", "devel", *std_cmake_args
    system "make", "install"
  end
end
