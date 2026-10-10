class Cloudcover < Formula
  desc "Analyze cloud SDK usage and generate permission policies"
  homepage "https://github.com/cyruscook/cloudcover"
  version "0.1.9"
  license "MIT"
  version_scheme 1

  livecheck do
    url :homepage
    regex(/^cloudcover-cli-v(\d+(?:\.\d+)+)$/i)
    strategy :git
  end

  on_macos do
    on_arm do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.1.9/cloudcover-cli-aarch64-apple-darwin.tar.gz"
      sha256 "1864feccf5da712d738d78959296d9cffba5dd318916c177ef5eaca7d178db81"
    end
    on_intel do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.1.9/cloudcover-cli-x86_64-apple-darwin.tar.gz"
      sha256 "bb5705378f12a1dca3f4c06da83b27d2a43e79feebcec57aab3b4755fc0a5718"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.1.9/cloudcover-cli-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "2141ff7fba3cd9efdf4e430438f0ade81585663b2bdbf897de5cf0d89ebf6db7"
    end
    on_intel do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.1.9/cloudcover-cli-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "153361a287b954da546646ccaa1830e694a18d70b3ed0a71077bbb89f03e8d9c"
    end
  end

  def install
    bin.install "cloudcover"
  end

  test do
    assert_match "Usage: cloudcover policy", shell_output("#{bin}/cloudcover --help")
  end
end
