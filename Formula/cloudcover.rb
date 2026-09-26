class Cloudcover < Formula
  desc "Analyze cloud SDK usage and generate permission policies"
  homepage "https://github.com/cyruscook/cloudcover"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.1.4/cloudcover-cli-aarch64-apple-darwin.tar.gz"
      sha256 "bf882ea65dec9c8b02ff7ac8d2d26dd594e354339ff3547a2d2f9d1bd2751f68"
    end
    on_intel do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.1.4/cloudcover-cli-x86_64-apple-darwin.tar.gz"
      sha256 "fa21a59d5b1267ac9d9cf0cdbea5822ecc34000e54fb6e5264c96d8f2010f121"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.1.4/cloudcover-cli-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "6399a9ba3595d7bb05da0857d2ab3c9e8f1f3fb13d51deb885fa2c113759cbe0"
    end
    on_intel do
      url "https://github.com/cyruscook/cloudcover/releases/download/cloudcover-cli-v0.1.4/cloudcover-cli-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "b55c3bba01531cf2fdfc7b17c2df73dda6c650e496c2753d24f68df50576d476"
    end
  end

  def install
    bin.install "cloudcover"
  end

  test do
    assert_match "Usage: cloudcover policy", shell_output("#{bin}/cloudcover --help")
  end
end
