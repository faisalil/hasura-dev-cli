class HasuraDev < Formula
  desc "Docker-free Hasura v2 development CLI runtime"
  homepage "https://github.com/faisalil/hasura-dev-cli"
  version "0.1.1"
  license "Apache-2.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/faisalil/hasura-dev-cli/releases/download/v0.1.1/hasura-dev-darwin-arm64.tar.gz"
      sha256 "afb9efb7892a82367aff32c127f9bcbaaed8e31dbf67a61cee5d738828071a8e"
    else
      url "https://github.com/faisalil/hasura-dev-cli/releases/download/v0.1.1/hasura-dev-darwin-amd64.tar.gz"
      sha256 "7b84a7235639b6b74e6411d8d93a3abe821a9d2d542d93757c4b4d9285ad016d"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/faisalil/hasura-dev-cli/releases/download/v0.1.1/hasura-dev-linux-arm64.tar.gz"
      sha256 "4bb5ab6f6136dd2e830db422bbd349ebf44c87ea435586c35d0527d278ccfa1c"
    else
      url "https://github.com/faisalil/hasura-dev-cli/releases/download/v0.1.1/hasura-dev-linux-amd64.tar.gz"
      sha256 "4c4891ae1c6a16bbb16b0c31f0bf5b260ccc233aca76a6de8cb96984fc6e6bce"
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
