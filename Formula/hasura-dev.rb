class HasuraDev < Formula
  desc "Docker-free Hasura v2 development CLI runtime"
  homepage "https://github.com/faisalil/hasura-dev-cli"
  version "0.1.3"
  license "Apache-2.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/faisalil/hasura-dev-cli/releases/download/v0.1.3/hasura-dev-darwin-arm64.tar.gz"
      sha256 "861efa33fd216acd836b308cdfd2dc82ebb7d18ac52be435dba199a036595d95"
    else
      url "https://github.com/faisalil/hasura-dev-cli/releases/download/v0.1.3/hasura-dev-darwin-amd64.tar.gz"
      sha256 "2d246219f5e856b0cfb032553be0510a29e6c1da576ad7635701ec3870df2a58"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/faisalil/hasura-dev-cli/releases/download/v0.1.3/hasura-dev-linux-arm64.tar.gz"
      sha256 "e0cf3794ca902cb600461edd668df75a55ecb76339a9b8e1c0a3f09d588d5e73"
    else
      url "https://github.com/faisalil/hasura-dev-cli/releases/download/v0.1.3/hasura-dev-linux-amd64.tar.gz"
      sha256 "111d37d5a192766b3662e749623e6224a277ccc833ce819b08250ad5a940d5f8"
    end
  end

  def install
    bin.install "hasura-dev"
  end

  test do
    output = shell_output("#{bin}/hasura-dev version 2>&1")
    assert_match "hasura cli", output
  end
end
