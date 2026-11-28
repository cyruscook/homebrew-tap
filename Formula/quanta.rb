class Quanta < Formula
  desc "Develop and edit photographs through a CLI and an MCP server"
  homepage "https://github.com/cyruscook/quanta"
  on_macos do
    url "https://github.com/cyruscook/quanta/releases/download/v1.0.1/quanta-1.0.1-macos-arm64.tar.gz"
    sha256 "f384a49065c639755d3f9e1eb1961edcb6e03535b242e687ca07b1a41af9e7ce"

    depends_on arch: :arm64
  end

  on_linux do
    url "https://github.com/cyruscook/quanta/releases/download/v1.0.1/quanta-1.0.1-linux-x86_64.tar.gz"
    sha256 "9e5df39ee8bfe689cbbc76dc58328edd711054eb2fa5744a5af439414ad791c7"

    depends_on arch: :x86_64
  end

  def install
    bin.install "quanta", "quanta-mcp"
    pkgshare.install "BINARY-NOTICE.md", "BUILDINFO", "DEPENDENCY-LICENSES.tsv", "RAWLER-LGPL-2.1.txt", "licenses"
    pkgshare.install "quanta-#{version}-source.tar.gz", "quanta-#{version}-source.tar.gz.sha256"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/quanta --version")
    request = <<~JSON
      {"jsonrpc":"2.0","id":1,"method":"initialize","params":{
        "protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"homebrew","version":"1"}
      }}
    JSON
    assert_match '"name":"quanta-mcp"', pipe_output(bin/"quanta-mcp", request.delete("\n") + "\n", 0)
    assert_path_exists pkgshare/"quanta-#{version}-source.tar.gz"
  end
end
