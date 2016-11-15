require "language/haskell"

class Elm < Formula
  include Language::Haskell::Cabal

  desc "Functional programming language for building browser-based GUIs"
  homepage "http://elm-lang.org"

  stable do
    url "https://github.com/elm-lang/elm-compiler/archive/0.18.0.tar.gz"
    sha256 "3ed70ab6e624c09dd251bb2f1e104752ebd3f50a062ddf92fff9cbec98d09850"

    resource "elm-package" do
      url "https://github.com/elm-lang/elm-package/archive/0.18.0.tar.gz"
      sha256 "5cf6e1ae0a645b426c0474cc7cd3f7d1605ffa1ac5756a39a8b2268ddc7ea0e9"
    end

    resource "elm-make" do
      url "https://github.com/elm-lang/elm-make/archive/0.18.0.tar.gz"
      sha256 "00c2d40128ca86454251d6672f49455265011c02aa3552a857af3109f337dbea"
    end

    resource "elm-repl" do
      url "https://github.com/elm-lang/elm-repl/archive/0.18.0.tar.gz"
      sha256 "be2b05d022ffa766fe186d5ad5da14385cec41ba7a4b2c18f2e0018351c99376"
    end

    resource "elm-reactor" do
      url "https://github.com/elm-lang/elm-reactor/archive/0.18.0.tar.gz"
      sha256 "736f84a08b10df07cfd3966aa5c7802957ab35d6d74f6322d4a69a0b9d75f4fe"
    end
  end

  bottle do
    sha256 "cdda51b539fd89e25375be053a0cc3a78ad09b242541fc1023a2d86b54dc3948" => :sierra
    sha256 "d7babb625ca0a614a434d2db6c4af692bb9a5d543461a4e5a39e61f2f86b3e53" => :el_capitan
    sha256 "ed537a9a30af32282badb2d61b52f653a073eec07efd08405b37b025de8b01e1" => :yosemite
    sha256 "63eb1dfad6bd3b17c07d9695082c7771f1ea2773ee3231ed6289ebf887f81013" => :mavericks
  end

  depends_on "ghc" => :build
  depends_on "cabal-install" => :build

  # GHC 8 compat
  # Fixes "No instance for (Num Json.Indent) arising from the literal '2'"
  # Reported 3 Jul 2016; PR subject "aeson-pretty: use Spaces with confIndent"
  patch do
    url "https://github.com/elm-lang/elm-compiler/pull/1431.patch"
    sha256 "4f11e645b4190eb3b0cbea7c641d4b28b307b811889f3b8206f45f6e53a5575b"
  end

  def install
    # elm-compiler needs to be staged in a subdirectory for the build process to succeed
    (buildpath/"elm-compiler").install Dir["*"]

    # GHC 8 compat
    # Fixes "cabal: Could not resolve dependencies"
    # Reported 25 May 2016: https://github.com/elm-lang/elm-compiler/issues/1397
    (buildpath/"cabal.config").write("allow-newer: base,time,transformers,HTTP,aeson-pretty\n")

    extras_no_reactor = ["elm-package", "elm-make", "elm-repl"]
    extras = extras_no_reactor + ["elm-reactor"]
    extras.each do |extra|
      resource(extra).stage buildpath/extra
    end

    cabal_sandbox do
      cabal_sandbox_add_source "elm-compiler", *extras
      cabal_install "--only-dependencies", "elm-compiler", *extras
      cabal_install "--prefix=#{prefix}", "elm-compiler", *extras_no_reactor

      # elm-reactor needs to be installed last because of a post-build dependency on elm-make
      ENV.prepend_path "PATH", bin

      cabal_install "--prefix=#{prefix}", "elm-reactor"
    end
  end

  test do
    src_path = testpath/"Hello.elm"
    src_path.write <<-EOS.undent
      import Html exposing (text)
      main = text "Hello, world!"
    EOS

    system bin/"elm", "package", "install", "elm-lang/html", "--yes"

    out_path = testpath/"index.html"
    system bin/"elm", "make", src_path, "--output=#{out_path}"
    assert File.exist?(out_path)
  end
end
