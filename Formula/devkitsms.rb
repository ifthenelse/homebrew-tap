class Devkitsms < Formula
  desc "SMS/GG/SG-1000/SC-3000/ColecoVision devkit (SDCC)"
  homepage "https://github.com/sverx/devkitSMS"
  url "https://github.com/sverx/devkitSMS/archive/8ce5a743b9709d9712e6fc28b8e9a2adae73c868.tar.gz"
  version "8ce5a74"
  sha256 "4985ec5f8f78f28df99c333572210ee2fe7f28b801338de385ce9de40ee9e370"
  # devkitSMS is a bundle of multiple components with different licenses:
  # - crt0: GPL-2.0 with a project-specific "special exception" (non-SPDX)
  # - many tools/libs: Unlicense (public domain dedication)
  # - some embedded code: WTFPL / ZX7 / other notices
  license :cannot_represent

  depends_on "sdcc"

  def install
    # Build host tools (best-effort)
    tool_dirs = %w[makesms ihx2sms makecvmc assets2banks folder2c].select { |d| (buildpath/d).directory? }

    tool_dirs.each do |d|
      cd d do
        if (Pathname.pwd/"Makefile").exist? || (Pathname.pwd/"makefile").exist?
          system "make"
        else
          c_files = Dir["*.c"]
          next if c_files.empty?

          system ENV.cc, *c_files, "-O2", "-o", d
        end

        candidates = [d, "makesms", "ihx2sms", "makecvmc", "assets2banks", "folder2c"]
        candidates.each do |name|
          path = Pathname.pwd/name
          bin.install path if path.exist? && path.executable?
        end
      end
    end

    # Build SMSlib.lib using SDCC
    if (buildpath/"SMSlib").directory?
      cd "SMSlib" do
        system "make" if (Pathname.pwd/"Makefile").exist?
      end
    end

    # Build crt0_sms.rel using SDCC
    if (buildpath/"crt0").directory?
      cd "crt0" do
        system "make" if (Pathname.pwd/"Makefile").exist?
      end
    end

    # Install SDK payload as data (stable path: $(brew --prefix)/share/devkitsms)
    pkgshare.install "SMSlib" if (buildpath/"SMSlib").exist?
    pkgshare.install "SGlib"  if (buildpath/"SGlib").exist?
    pkgshare.install "PSGlib" if (buildpath/"PSGlib").exist?
    pkgshare.install "MBMlib" if (buildpath/"MBMlib").exist?
    pkgshare.install "crt0"   if (buildpath/"crt0").exist?

    pkgshare.install "README.md" if (buildpath/"README.md").exist?
  end

  def caveats
    kit = opt_share/"devkitsms"
    <<~EOS
      devkitSMS data has been installed to:
        #{kit}

      Recommended project integration (headers + libs)

      1) Optional: export a stable DEVKITSMS path
           export DEVKITSMS="#{kit}"

      2) C include paths (typical)
           -I#{kit}/SMSlib
           -I#{kit}/SMSlib/src
         (and, if you use them)
           -I#{kit}/SGlib
           -I#{kit}/PSGlib
           -I#{kit}/MBMlib

      3) Common SDCC flags used with SMSlib
           --peep-file #{kit}/SMSlib/src/peep-rules.txt
           --reserve-regs-iy

      4) Linking
         This formula installs library *sources* under #{kit}.
         You typically build the .lib/.a outputs as part of your project (or once, then reuse),
         then link them in your final SDCC step.

         Example Makefile snippet (adjust lib names/paths to your build output):

           DEVKITSMS ?= #{kit}
           CFLAGS  += -mz80 --opt-code-speed --reserve-regs-iy \\
                     -I$(DEVKITSMS)/SMSlib -I$(DEVKITSMS)/SMSlib/src
           CFLAGS  += --peep-file $(DEVKITSMS)/SMSlib/src/peep-rules.txt

           # Example: if you produce build/SMSlib.lib
           LDFLAGS += build/SMSlib.lib

      Notes
      - Use the opt path above instead of the Cellar path for stability across upgrades.
      - Tools (if built from upstream directories) are installed in:
          #{opt_bin}
    EOS
  end

  test do
    kit = opt_share/"devkitsms"

    # Deterministic payload checks (installed as data)
    assert_path_exists kit/"SMSlib/src/SMSlib.h"
    assert_path_exists kit/"SMSlib/src/peep-rules.txt"
    assert_path_exists kit/"SMSlib/SMSlib.lib"

    # Compile-only smoke test using installed headers + peep rules
    (testpath/"main.c").write <<~C
      #include <SMSlib.h>
      void main(void) {
        SMS_init();
        SMS_displayOn();
        for(;;) { SMS_waitForVBlank(); }
      }
    C

    system "sdcc", "-mz80", "--opt-code-speed", "--reserve-regs-iy",
                   "--peep-file", kit/"SMSlib/src/peep-rules.txt",
                   "-I#{kit}/SMSlib", "-I#{kit}/SMSlib/src",
                   "-c", testpath/"main.c",
                   "-o", testpath/"main.rel"

    assert_path_exists testpath/"main.rel"
  end
end
