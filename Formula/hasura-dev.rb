class HasuraDev < Formula
  desc "Docker-free Hasura v2 development CLI runtime"
  homepage "https://github.com/faisalil/hasura-dev-cli"
  version "0.1.2"
  license "Apache-2.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/faisalil/hasura-dev-cli/releases/download/v0.1.2/hasura-dev-darwin-arm64.tar.gz"
      sha256 "f0c50c4c7838443c259480a981d4270f23456c06cfce50b015d3bc14504478c7"
    else
      url "https://github.com/faisalil/hasura-dev-cli/releases/download/v0.1.2/hasura-dev-darwin-amd64.tar.gz"
      sha256 "ddd349281db161797ee755a734f989e683fcdf58fe9eb42d8d3b707c4f20003b"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/faisalil/hasura-dev-cli/releases/download/v0.1.2/hasura-dev-linux-arm64.tar.gz"
      sha256 "7a686072e0fe9766f4ca2d6b4be756cfcabf3a74be517ecbdb6c1b8af393a081"
    else
      url "https://github.com/faisalil/hasura-dev-cli/releases/download/v0.1.2/hasura-dev-linux-amd64.tar.gz"
      sha256 "7b4ffc6dd47667fa5d6b6eedd1cee04bb9b83165e619efbc9e90c1c4241bf28c"
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
