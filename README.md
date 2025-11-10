---
lang: en
---

# Nix flake templates for quick dev environments

[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

Initialize an environment with the below command (or better as a script),
passing the wanted stack as the `$1` argument.

```shell
nix flake init -t "github:gfauredev/dev-templates#$1"
direnv allow
```

| Stack (language, tools…)         | Nix Flake Template                    |
| :------------------------------- | :------------------------------------ |
| [Bun]                            | [`bun`](./bun/)                       |
| [CadQuery]/[Build123d]           | [`cadquery`](./cadquery-build123d/)   |
| [C]/[C++]                        | [`c-cpp`](./c-cpp/)                   |
| [Clojure]                        | [`clojure`](./clojure/)               |
| [Cue]                            | [`cue`](./cue/)                       |
| [Dhall]                          | [`dhall`](./dhall/)                   |
| [Elixir]                         | [`elixir`](./elixir/)                 |
| [Elm]                            | [`elm`](./elm/)                       |
| Empty                            | [`empty`](./empty)                    |
| [Gleam]                          | [`gleam`](./gleam/)                   |
| [Go]                             | [`go`](./go/)                         |
| [Hashicorp] tools                | [`hashi`](./hashi/)                   |
| [Haskell]                        | [`haskell`](./haskell/)               |
| [Haxe]                           | [`haxe`](./haxe/)                     |
| [Java]                           | [`java`](./java/)                     |
| [Jupyter]                        | [`jupyter`](./jupyter/)               |
| [Kotlin]                         | [`kotlin`](./kotlin/)                 |
| [LaTeX]                          | [`latex`](./latex/)                   |
| [Lua]                            | [`lua`](./lua/)                       |
| [Nickel]                         | [`nickel`](./nickel/)                 |
| [Nim]                            | [`nim`](./nim/)                       |
| [Nix]                            | [`nix`](./nix/)                       |
| [Node.js][node]                  | [`node`](./node/)                     |
| [OCaml]                          | [`ocaml`](./ocaml/)                   |
| [Odin]                           | [`odin`](./odin/)                     |
| [OpenSCAD]                       | [`opa`](./openscad)                   |
| [Open Policy Agent][opa]         | [`opa`](./opa)                        |
| [PHP]                            | [`php`](./php/)                       |
| [PlatformIO]                     | [`platformio`](./platformio/)         |
| [Protobuf]                       | [`protobuf`](./protobuf/)             |
| [Pulumi]                         | [`pulumi`](./pulumi/)                 |
| [Purescript]                     | [`purescript`](./purescript/)         |
| [Python]                         | [`python`](./python/)                 |
| [R]                              | [`r`](./r/)                           |
| [Ruby]                           | [`ruby`](./ruby/)                     |
| [Rust]                           | [`rust`](./rust/)                     |
| [Scala]                          | [`scala`](./scala/)                   |
| [Shell]                          | [`shell`](./shell/)                   |
| [SWI-prolog]                     | [`swi-prolog`](./swi-prolog/)         |
| [Swift]                          | [`swift`](./swift)                    |
| [Typst]                          | [`typst`](./typst)                    |
| [Vagrant]                        | [`vagrant`](./vagrant/)               |
| [Vlang]                          | [`vlang`](./vlang/)                   |
| [Web] (HTML/CSS/TS)              | [`web`](./web/)                       |
| [Zig]                            | [`zig`](./zig/)                       |

## Template contents

> What each template includes

### [`bun`](./bun/)

- [bun]

### [`c-cpp`](./c-cpp/)

Default compiler gcc is replaced by **clang**.

A basic CMakeLists.txt is provided.

- [clang-tools] CLIs
- [cmake] build automation tool
- [cmake-lsp] build automation tool LSP
- [cppcheck] static analysis
- [doxygen] documentation generation
- [gnumake] build automation tool
- [gtest] testing framework
- [lcov] code coverage analyzer
- [lldb] clang debug adapter
- [pkg-config] libraries finder
- [valgrind] debugging, profiling

#### Disabled

- [codespell] spell checker
- [conan] package manager
- [gdb] debugger
- [vcpkg] library manager
- [vcpkg-tool] library manager tools

### [`clojure`](./clojure/)

- [Clojure]
- [Boot]
- [Leiningen]

### [`cue`](./cue/)

- [Cue]

### [`dhall`](./dhall)

- [Dhall]
- [dhall-bash]
- [dhall-docs]
- [dhall-json]
- [dhall-lsp-server]
- [dhall-nix]
- [dhall-nixpkgs]
- [dhall-openapi]
- [dhall-toml]
- [dhall-yaml]

### [`elixir`](./elixir/)

- [Elixir], including [mix] and [IEx]
- [gigalixir] (Linux only)

### [`elm`](./elm/)

- [Elm]
- [elm2nix]

### [Empty](./empty/)

A dev template that's fully customizable.

### [`gleam`](./gleam/)

- [Gleam]

### [`go`](./go/)

- [Go]
- Standard Go tools ([goimports], [godoc], and others)
- [golangci-lint]

### [`hashi`](./hashi/)

- [Packer]
- [Terraform]
- [Nomad]
- [Vault]
- [nomad-autoscaler]
- [nomad-pack]
- [levant]
- [damon]
- [Terragrunt]
- [tflint]

### [`haskell`](./haskell/)

- [GHC][haskell]
- [cabal]

### [`haxe`](./haxe/)

- [Haxe]

### [`java`](./java/)

- [Java]
- [Maven]
- [Gradle]
- [jdtls]

### [`jupyter`](./jupyter/)

- [Jupyter core][jupyter]

### [`kotlin`](./kotlin/)

- [Kotlin]
- [Gradle]

### [`latex`](./latex/)

- [texlive]
- [tectonic]
- [texlab]

### [`lua`](./lua/)

- [lua]
- [lua-lsp]

### [`lean4`](./lean4/)

- [Lean]

### [`nickel`](./nickel/)

- [Nickel]

### [`nim`](./nim)

- [Nim]
- [nimble]

### [`nix`](./nix/)

- [Cachix]
- [dhall-to-nix]
- [lorri]
- [niv]
- [nixfmt]
- [statix]
- [vulnix]

### [`node`](./node/)

- [Node.js][node]
- [npm]
- [pnpm]
- [Yarn]
- [node2nix]

### [`ocaml`](./ocaml/)

- [OCaml]
- [Dune]
- [odoc]
- [ocamlformat]

### [`odin`](./odin/)

- [Odin]

### [`openscad`](./openscad/)

- [OpenSCAD] compiler generating 3D models
- [OpenSCAD-LSP] LSP for the same-named language
- [sca2d] Static analysis for OpenSCAD

### [`opa`](./opa/)

- [Open Policy Agent][opa]
- [Conftest]

### [`php`](./php/)

- [PHP]
- [Composer]

### [`platformio`](./platformio/)

- [PlatformIO]

### [`protobuf`](./protobuf/)

- The [Buf CLI][buf]
- [protoc][protobuf]

### [`pulumi`](./pulumi/)

- [Pulumi]
- [Python]
- [Go]
- [Node.js][node]
- [dotnet]
- [Java] and [Maven]
- [jq]

### [`purescript`](./purescript/)

- [Purescript] (purs)
- [Spago]
- [purescript-language-server]
- [purs-tidy]

### [`python`](./python/)

- [Python]
- [pip]
- [ruff] lint and format
- [mypy] type checking, static analysis
- [rope] smart refactoring
- [python-lsp-server] python LSP
- [pylsp-mypy] mypy LSP
- [pylsp-rope] rope LSP

#### [`python-uv`](./python-uv/)

- [uv] Packages and environment manager
- [ruff] lint and format
- [mypy] type checking, static analysis
- [rope] smart refactoring
- [python-lsp-server] python LSP
- [pylsp-mypy] mypy LSP
- [pylsp-rope] rope LSP

### [`r`](./r/)

- [R]
- [rmarkdown]
- [knitr] ([pandoc] and [texlive])

### [`ruby`](./ruby/)

- [Ruby], plus the standard Ruby tools (`bundle`, `gem`, etc.)

### [`rust`](./rust/)

- [Rust], including [cargo], [Clippy], and the other standard tools,
  with the Rust version determined as follows, in order
  - From the `rust-toolchain.toml` file if present
  - From the `rust-toolchain` file if present
  - Version if neither is present

- [rust-analyzer]
- [lldb] clang debug adapter
- [cargo-edit]
- [cargo-deny]

### [`scala`](./scala/)

- [Scala] (plus [Java])
- [sbt]

### [`shell`](./shell/)

- [bash-lsp] language server
- [shellcheck]
- [shfmt] formatter

### [`swi-prolog`](./swi-prolog/)

- [swipl][swi-prolog]

### [`swift`](./swift/)

- [Swift]
- [sourcekit-lsp]

### [`typst`](./typst/)

- [Typst] compiler generating PDFs
- [Tinymist] LSP for Typst
- [Typstyle] formater for Typst

### [`vagrant`](./vagrant/)

- [Vagrant]

### [`vlang`](./vlang/)

- [Vlang]

### [`zig`](./zig/)

- [Zig]
- [LLDB]
- [ZLS]

[bash-lsp]: https://todo.com
[boot]: https://boot-clj.com
[buf]: https://github.com/bufbuild/buf
[build123d]: https://build123d.readthedocs.io
[bun]: https://bun.sh
[cadquery]: https://cadquery.readthedocs.io
[C]: https://open-std.org/jtc1/sc22/wg14
[C++]: https://isocpp.org
[cabal]: https://haskell.org/cabal
[cachix]: https://cachix.org
[cargo]: https://doc.rust-lang.org/cargo
[cargo-audit]: https://crates.io/crates/cargo-audit
[cargo-deny]: https://crates.io/crates/cargo-deny
[cargo-edit]: https://crates.io/crates/cargo-edit
[clang-tools]: https://clang.llvm.org
[clippy]: https://github.com/rust-lang/rust-clippy
[clojure]: https://clojure.org
[cmake]: https://cmake.org
[cmake-lsp]: https://todo.com
[gnumake]: https://todo.com
[codespell]: https://github.com/codespell-project/codespell
[composer]: https://getcomposer.org
[conan]: https://conan.io
[conftest]: https://conftest.dev
[cppcheck]: http://cppcheck.sourceforge.net
[cue]: https://cuelang.org
[damon]: https://github.com/hashicorp/damon
[dhall]: https://dhall-lang.org
[dhall-bash]: https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-bash
[dhall-docs]: https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-docs
[dhall-json]: https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-json
[dhall-lsp-server]: https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-lsp-server
[dhall-nix]: https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-nix
[dhall-nixpkgs]: https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-nixpkgs
[dhall-openapi]: https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-openapi
[dhall-to-nix]: https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-nix
[dhall-toml]: https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-toml
[dhall-yaml]: https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-yaml
[dotnet]: https://dotnet.microsoft.com/en-us
[doxygen]: https://doxygen.nl
[dune]: https://dune.build
[elixir]: https://elixir-lang.org
[elm]: https://elm-lang.org
[elm2nix]: https://github.com/cachix/elm2nix
[flake-utils]: https://github.com/numtide/flake-utils
[gdb]: https://gnu.org/software/gdb
[gigalixir]: https://gigalixir.com
[gleam]: https://gleam.run
[go]: https://go.dev
[godoc]: https://pkg.go.dev/golang.org/x/tools/cmd/godoc
[goimports]: https://pkg.go.dev/golang.org/x/tools/cmd/goimports
[golangci-lint]: https://github.com/golangci/golangci-lint
[gradle]: https://gradle.org
[gtest]: https://github.com/google/googletest
[hashicorp]: https://hashicorp.com
[haskell]: https://haskell.org
[haxe]: https://haxe.org
[iex]: https://hexdocs.pm/iex/IEx.html
[java]: https://java.com
[jdtls]: https://projects.eclipse.org/projects/eclipse.jdt.ls
[jq]: https://jqlang.github.io/jq
[jupyter]: https://jupyter.org
[knitr]: https://yihui.org/knitr
[kotlin]: https://kotlinlang.org
[latex]: https://latex-project.org
[lean]: https://lean-lang.org
[lcov]: https://ltp.sourceforge.net/coverage/lcov.php
[lua]: https://www.lua.org
[lua-lsp]: https://www.lua.org
[leiningen]: https://leiningen.org
[levant]: https://github.com/hashicorp/levant
[lldb]: https://lldb.llvm.org
[lorri]: https://github.com/target/lorri
[maven]: https://maven.apache.org
[mix]: https://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html
[mono]: https://mono-project.com
[msbuild]: https://github.com/dotnet/msbuild
[mypy]: https://todo.com
[nickel]: https://nickel-lang.org
[nim]: https://nim-lang.org
[nimble]: https://github.com/nim-lang/nimble
[niv]: https://github.com/nmattia/niv
[nix]: https://nixos.org
[nixfmt]: https://github.com/serokell/nixfmt
[nixpkgs]: https://github.com/NixOS/nixpkgs
[nix-direnv]: https://github.com/nix-community/nix-direnv
[node]: https://nodejs.org
[node2nix]: https://github.com/svanderburg/node2nix
[nomad]: https://nomadproject.io
[nomad-autoscaler]: https://github.com/hashicorp/nomad-autoscaler
[nomad-pack]: https://github.com/hashicorp/nomad-pack
[npm]: https://npmjs.org
[ocaml]: https://ocaml.org
[ocamlformat]: https://github.com/ocaml-ppx/ocamlformat
[odoc]: https://github.com/ocaml/odoc
[odin]: https://github.com/odin-lang/Odin
[omnisharp-roslyn]: https://github.com/OmniSharp/omnisharp-roslyn
[opa]: https://openpolicyagent.org
[openscad]: https://openscad.org
[openscad-lsp]: https://openscad.org
[pandoc]: https://pandoc.org
[packer]: https://packer.io
[pip]: https://pypi.org/project/pip
[phoenix]: https://phoenixframework.org
[php]: https://php.net
[platformio]: https://platformio.org
[python]: https://python.org
[python-lsp-server]: https://todo.com
[pkg-config]: https://todo.com
[pylsp-mypy]: https://todo.com
[pylsp-rope]: https://todo.com
[pnpm]: https://pnpm.io
[protobuf]: https://developers.google.com/protocol-buffers
[pulumi]: https://pulumi.com
[purescript]: https://github.com/purescript/purescript
[purescript-language-server]: https://github.com/nwolverson/purescript-language-server
[purs-tidy]: https://github.com/natefaubion/purescript-tidy
[r]: https://r-project.org
[rmarkdown]: https://rmarkdown.rstudio.com
[ruby]: https://ruby-lang.org
[rust]: https://rust-lang.org
[rust-analyzer]: https://rust-analyzer.github.io
[ruff]: https://todo.com
[rope]: https://todo.com
[scala]: https://scala-lang.org
[sca2d]: https://openscad.org
[shellcheck]: https://shellcheck.net
[statix]: https://github.com/nerdypepper/statix
[shfmt]: https://todo.com
[sbt]: https://scala-sbt.org
[sourcekit-lsp]: https://github.com/swiftlang/sourcekit-lsp
[spago]: https://github.com/purescript/spago
[shell]: https://cgit.git.savannah.gnu.org/cgit/bash.git
[swi-prolog]: https://www.swi-prolog.org
[swift]: https://swift.org
[tectonic]: https://tectonic-typesetting.github.io
[terraform]: https://terraform.io
[terragrunt]: https://terragrunt.gruntwork.io
[texlab]: https://github.com/latex-lsp/texlab
[texlive]: https://tug.org/texlive
[tflint]: https://github.com/terraform-linters/tflint
[typst]: https://typst.app
[tinymist]: https://todo.com
[typstyle]: https://todo.com
[uv]: https://todo.com
[vault]: https://vaultproject.io
[valgrind]: https://todo.com
[vcpkg]: https://vcpkg.io
[vcpkg-tool]: https://github.com/microsoft/vcpkg-tool
[vulnix]: https://github.com/flyingcircusio/vulnix
[yarn]: https://yarnpkg.com
[vagrant]: https://developer.hashicorp.com/vagrant
[vlang]: https://vlang.io
[web]: https://nodejs.org
[zig]: https://ziglang.org
[zls]: https://github.com/zigtools/zls
