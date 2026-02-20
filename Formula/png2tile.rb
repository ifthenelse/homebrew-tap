class Png2tile < Formula
  desc "Convert PNG images into Sega Master System tile format"
  homepage "https://github.com/yuv422/png2tile"
  url "https://github.com/yuv422/png2tile/archive/4822a3a0cfdb59aa287008324222b2a5a26e8bc3.tar.gz"
  version "4822a3a"
  sha256 "0ddcad0f1b899f1b17a531e37197e922644a41a4378b4dd3da75e68bf84deaa8"
  license "MIT"

  depends_on "cmake" => :build
  depends_on "imagemagick" => :test

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    bin.install "build/png2tile"
  end

  test do
    system "magick", "-size", "8x8", "xc:black",
                    "-fill", "white", "-draw", "point 0,0",
                    "+dither", "-colors", "2",
                    "PNG8:in.png"

    system bin/"png2tile", "in.png",
          "-binary",
          "-savetiles", "tiles.bin",
          "-savepalette", "pal.bin",
          "-savetilemap", "map.bin"

    assert_path_exists testpath/"tiles.bin"
    assert_path_exists testpath/"pal.bin"
    assert_path_exists testpath/"map.bin"
  end
end
