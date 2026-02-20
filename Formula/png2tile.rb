class Png2tile < Formula
  desc "Convert PNG images into Sega Master System tile format"
  homepage "https://github.com/yuv422/png2tile"
  url "https://github.com/yuv422/png2tile/archive/refs/heads/master.tar.gz"
  version "4822a3a"
  sha256 "e9e575cc5cdcaf34a2699fd648abb7db890a1bf08a85dc5b92a3ea233febc22b"
  license "MIT"

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    bin.install "build/png2tile"
  end

  test do
    # 1x1 PNG (transparent) as base64; just to exercise the binary.
    png_b64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMB/6X9l3sAAAAASUVORK5CYII="
    (testpath/"in.png").binwrite(Base64.decode64(png_b64))

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
