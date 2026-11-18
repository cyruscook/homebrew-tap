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
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.3.4/cloudcover-cli-aarch64-apple-darwin.tar.gz"
      sha256 "f995e1ab42e83b78a20109e21fe8e6b6dbe81e251886f2fc330a180e7f1dae45"
    end
    on_intel do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.3.4/cloudcover-cli-x86_64-apple-darwin.tar.gz"
      version "0.3.4"
      sha256 "d4513a1db686ae9a3a4d0f7084e1395bdb97cb6ca4a596cdd737619974d8e534"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.3.4/cloudcover-cli-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "f104d273c40f7a4d16d58f498bc11fb485b9aa5545391c9f3ff695efe2f6ccd6"
    end
    on_intel do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.3.4/cloudcover-cli-x86_64-unknown-linux-gnu.tar.gz"
      version "0.3.4"
      sha256 "5cf97cda51ff6c1424065f19d5ce5c5e2f4e737fcfe8baa6d895a460f5575a05"
    end
  end

  def install
    bin.install "cloudcover"
  end

  test do
    assert_match "Usage: cloudcover policy", shell_output("#{bin}/cloudcover --help")
  end
end
