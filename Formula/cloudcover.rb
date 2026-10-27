class Cloudcover < Formula
  desc "Analyze cloud SDK usage and generate permission policies"
  homepage "https://github.com/cyruscook/cloudcover"
  license "MIT"
  version_scheme 1

  livecheck do
    url :homepage
    regex(/^cloudcover-cli-v(\d+(?:\.\d+)+)$/i)
    strategy :git
  end

  on_macos do
    on_arm do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.2.2/cloudcover-cli-aarch64-apple-darwin.tar.gz"
      sha256 "a44ac1acaf30fd98474da00993aaa76777eedeb23fb2348f5e7ff5fa445687ab"
    end
    on_intel do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.2.2/cloudcover-cli-x86_64-apple-darwin.tar.gz"
      version "0.2.2"
      sha256 "8fdab7adf29cd953c4491d38fea9fef150e2e788c52b9478b5828b3167debfc4"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.2.2/cloudcover-cli-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "c223fe8819e7a0e8677c35f50c7439e9be53a196a034ef87b96aa3a5d04afaf9"
    end
    on_intel do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.2.2/cloudcover-cli-x86_64-unknown-linux-gnu.tar.gz"
      version "0.2.2"
      sha256 "904347e0ea72093ecfa8a1b51ed07bdb36d880a32c64905bde2a5ccbf32d6a6d"
    end
  end

  def install
    bin.install "cloudcover"
  end

  test do
    assert_match "Usage: cloudcover policy", shell_output("#{bin}/cloudcover --help")
  end
end
