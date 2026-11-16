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
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.3.1/cloudcover-cli-aarch64-apple-darwin.tar.gz"
      sha256 "4602fb8e065e83d7ee91fc37079af920379dab9d224799c03a826b3976b0d932"
    end
    on_intel do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.3.1/cloudcover-cli-x86_64-apple-darwin.tar.gz"
      version "0.3.1"
      sha256 "5aeabeb80996f5625174dd84b82972a27446147d0db3c81d170390b694ba2e5d"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.3.1/cloudcover-cli-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "0e8482d268fbcb88549d32d62971f5a228695a572185f3cb08ce135842e5cda0"
    end
    on_intel do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.3.1/cloudcover-cli-x86_64-unknown-linux-gnu.tar.gz"
      version "0.3.1"
      sha256 "fa61642390fefe4c3e131eebb7cca30a483caace35795c37c8b737df97e6bb5d"
    end
  end

  def install
    bin.install "cloudcover"
  end

  test do
    assert_match "Usage: cloudcover policy", shell_output("#{bin}/cloudcover --help")
  end
end
