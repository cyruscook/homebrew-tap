class Quanta < Formula
  desc "Develop and edit photographs through a CLI and an MCP server"
  homepage "https://github.com/cyruscook/quanta"
  url "https://github.com/cyruscook/quanta/releases/download/v1.0.0/quanta-1.0.0-linux-x86_64.tar.gz"
  version "1.0.0"
  sha256 "829cc85c1b04a0bd00de6c745f8ec910b0f6ccd337206edbaf820b01fea495a4"

  depends_on arch: :x86_64
  depends_on :linux

  def install
    bin.install "quanta", "quanta-mcp"
    pkgshare.install "BINARY-NOTICE.md", "BUILDINFO", "DEPENDENCY-LICENSES.tsv", "RAWLER-LGPL-2.1.txt", "licenses"
    pkgshare.install "quanta-#{version}-source.tar.gz", "quanta-#{version}-source.tar.gz.sha256"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/quanta --version")
    request = '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},' \
              '"clientInfo":{"name":"homebrew","version":"1"}}}'
    assert_match '"name":"quanta-mcp"', pipe_output("#{bin}/quanta-mcp", "#{request}\n", 0)
    assert_path_exists pkgshare/"quanta-#{version}-source.tar.gz"
  end
end
