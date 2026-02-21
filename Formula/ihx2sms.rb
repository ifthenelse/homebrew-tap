class Ihx2sms < Formula
  desc "Convert Intel HEX (.ihx) files to Sega Master System ROM (.sms)"
  homepage "https://github.com/sverx/devkitSMS"
  url "https://github.com/sverx/devkitSMS/archive/8ce5a743b9709d9712e6fc28b8e9a2adae73c868.tar.gz"
  version "8ce5a74"
  sha256 "4985ec5f8f78f28df99c333572210ee2fe7f28b801338de385ce9de40ee9e370"
  license "Unlicense"

  def install
    cd "ihx2sms/src" do
      system ENV.cc, "ihx2sms.c", "-O2", "-o", "ihx2sms"
      bin.install "ihx2sms"
    end
  end

  test do
    # Create a minimal Intel HEX file for testing
    (testpath/"test.ihx").write <<~HEX
      :10000000C3030021FFFF22DFFFFF0000000000B9
      :1000100000000000000000000000000000000000E0
      :00000001FF
    HEX

    system "#{bin}/ihx2sms", testpath/"test.ihx", testpath/"test.sms"
    assert_path_exists testpath/"test.sms"
    assert_predicate testpath/"test.sms", :file?
  end
end
