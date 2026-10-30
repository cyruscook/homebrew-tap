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
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.2.3/cloudcover-cli-aarch64-apple-darwin.tar.gz"
      sha256 "57c62ec64c962c7e1aee37c28adab84281201f104d114b22b0f7c97832041d88"
    end
    on_intel do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.2.3/cloudcover-cli-x86_64-apple-darwin.tar.gz"
      version "0.2.3"
      sha256 "4fe697f73b9c12864b5a1cda1db7ba43137240fe73a7794188f2c56c9fa8f4e8"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.2.3/cloudcover-cli-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "76963c6f2e6d1b92fb3abf95074e067650dd98e91492d752e81540bddc37414b"
    end
    on_intel do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.2.3/cloudcover-cli-x86_64-unknown-linux-gnu.tar.gz"
      version "0.2.3"
      sha256 "0610458262283cfcb9a292e76111a3dcce6ff11bf8177eecdf91206fff8714e7"
    end
  end

  def install
    bin.install "cloudcover"
  end

  test do
    assert_match "Usage: cloudcover policy", shell_output("#{bin}/cloudcover --help")
  end
end
