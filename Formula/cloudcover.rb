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
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.3.6/cloudcover-cli-aarch64-apple-darwin.tar.gz"
      sha256 "003b9f1d9a307947c78ed2c37f9898c52c0679d4c719e7dd40fe9a4855317c37"
    end
    on_intel do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.3.6/cloudcover-cli-x86_64-apple-darwin.tar.gz"
      version "0.3.6"
      sha256 "fd37eb7a26419f05b6e5e56ae5ca7ec6d49928f3308cfd95a1ede407c92e8359"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.3.6/cloudcover-cli-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "38f7c80dda93f50c95ccc791a3833f44bd5d7adbc003f33bac13b1fe55679fd2"
    end
    on_intel do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.3.6/cloudcover-cli-x86_64-unknown-linux-gnu.tar.gz"
      version "0.3.6"
      sha256 "2111e5c86992d573fbcab22e802c2fe9d428409a26c10caf143d7b631690cdc6"
    end
  end

  def install
    bin.install "cloudcover"
  end

  test do
    assert_match "Usage: cloudcover policy", shell_output("#{bin}/cloudcover --help")
  end
end
