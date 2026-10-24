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
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.2.1/cloudcover-cli-aarch64-apple-darwin.tar.gz"
      sha256 "6abfe4f621d4d42f1746b564b988abd9e73602756089a41c3f24a339eff9f3da"
    end
    on_intel do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.2.1/cloudcover-cli-x86_64-apple-darwin.tar.gz"
      version "0.2.1"
      sha256 "8e30a06844d083bc869ecc9e9a79eee77f183d07adc14d0444d12617a52a274c"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.2.1/cloudcover-cli-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "ee228677d2b3ac557aef749724e61263338ed295b1c62cc3670954db9c87f2f8"
    end
    on_intel do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.2.1/cloudcover-cli-x86_64-unknown-linux-gnu.tar.gz"
      version "0.2.1"
      sha256 "f1a89fdd7497429ee0fa631b3f752ac44dd498d65f49d465f78f8abcb3a16da8"
    end
  end

  def install
    bin.install "cloudcover"
  end

  test do
    assert_match "Usage: cloudcover policy", shell_output("#{bin}/cloudcover --help")
  end
end
