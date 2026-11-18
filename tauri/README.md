<!-- LTeX: language=en-GB -->

<!--toc:start-->

- [Tauri React SQLite Project](#tauri-react-sqlite-project)
  - [Tooling and Dependencies](#tooling-and-dependencies)
  - [Building and Running](#building-and-running)
  - [Licensing and Credits](#licensing-and-credits)

<!--toc:end-->

# Tauri React SQLite Project

## Tooling and Dependencies

| Purpose            | Methodology            |
| ------------------ | ---------------------- |
| Project versioning | [SemVer]               |
| Commit messages    | [Conventional Commits] |
| Branch naming      | [Conventional Branch]  |
| Branching model    | [GitHub Flow]          |
| Changes submission | [GitHub Pull Requests] |
| Issue tracking     | [GitHub Issues]        |

## Building and Running

The project uses [Nix] to download all (proper versions of) required
dependencies, configure the development environment (shell) and build the
application, reproducibly. The [Nix] environment and tooling is defined in
[`flake.nix`], enable it with `nix develop` or automatically at `cd` with an
allowed [`.envrc`](.envrc) (`direnv allow`) via [`direnv`] (recommended).

Release builds must be pure reproducible `nix build`, but faster incremental
builds may be preferred for development speed.

## Licensing and Credits

This project is licensed under the [GPL-3.0].

[Cargo]: https://doc.rust-lang.org/cargo
[cargo test]: https://doc.rust-lang.org/cargo/commands/cargo-test.html
[cargo-llvm-cov]: https://github.com/taiki-e/cargo-llvm-cov
[Clippy]: https://github.com/rust-lang/rust-clippy
[Conventional Commits]: https://www.conventionalcommits.org
[Conventional Branch]: https://conventional-branch.github.io
[direnv]: https://direnv.net
[`direnv`]: https://direnv.net
[`flake.nix`]: flake.nix
[GPL-3.0]: https://www.gnu.org/licenses/gpl-3.0.en.html
[Guilhem Fauré]: https://www.guilhemfau.re
[Git]: https://git-scm.com
[GitHub Pull Requests]: https://github.com/gfauredev/project/pulls
[GitHub Issues]: https://github.com/gfauredev/project/issues
[GitHub Flow]: https://githubflow.github.io
[Helix]: https://helix-editor.com
[lcov]: https://github.com/linux-test-project/lcov
[lldb]: https://lldb.llvm.org
[llvm-cov]: https://llvm.org/docs/CommandGuide/llvm-cov.html
[Maestro]: https://maestro.dev
[nextest]: https://nexte.st
[Nix]: https://nixos.org
[pwa]: https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps
[pagespeed insights]: https://pagespeed.web.dev
[renovate]: https://www.mend.io/renovate
[rust-analyzer]: https://rust-analyzer.github.io
[rust]: https://www.rust-lang.org
[rustc]: https://doc.rust-lang.org/rustc
[rustdoc]: https://doc.rust-lang.org/rustdoc
[rustfmt]: https://github.com/rust-lang/rustfmt
[VS Code]: https://code.visualstudio.com
[SemVer]: https://semver.org
[Serde]: https://serde.rs
[IndexedDB]: https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API
[Rexie]: https://github.com/wasmerio/rexie
[SQLite]: https://www.sqlite.org/index.html
[Rusqlite]: https://github.com/rusqlite/rusqlite
[Reqwest]: https://github.com/seanmonstar/reqwest
[Time]: https://github.com/time-rs/time
[Tokio]: https://tokio.rs
[yellow labs]: https://yellowlab.tools
[Web-sys]: https://rustwasm.github.io/wasm-bindgen/web-sys/index.html
