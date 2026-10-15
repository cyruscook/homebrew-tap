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
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.2.0/cloudcover-cli-aarch64-apple-darwin.tar.gz"
      sha256 "ef41278661d37d88007a0249c1fe00679413b6bcb00c91635ee0e930d672f988"
    end
    on_intel do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.2.0/cloudcover-cli-x86_64-apple-darwin.tar.gz"
      version "0.2.0"
      sha256 "1a6013ffaab8f4771bbe943618e04e7808ae60cf72dfe208e0ae27dfe4200d26"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.2.0/cloudcover-cli-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "e46d23028dd00ebaf27e8058c8cc4da5ed78e8c0a86d5d15befc0c93acfb9d5e"
    end
    on_intel do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.2.0/cloudcover-cli-x86_64-unknown-linux-gnu.tar.gz"
      version "0.2.0"
      sha256 "051060193a1770640233f94a34ffac28d82a16c5a2cd3577750d1216d1314a2d"
    end
  end

  def install
    bin.install "cloudcover"
  end

  test do
    assert_match "Usage: cloudcover policy", shell_output("#{bin}/cloudcover --help")
  end
end
