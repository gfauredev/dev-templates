---
lang: en-US
---

# build123d on NixOS

Reproducible [build123d](https://github.com/gumyr/build123d) environment for
NixOS. build123d and OCP aren't in nixpkgs, so the flake uses **uv2nix**.
`uv.lock` pins the exact PyPI wheels, and Nix builds them into a virtualenv.
Each wheel gets its native libraries through `autoPatchelf`, so no `nix-ld`, FHS
env, conda or OCCT compile is needed.

## Daily workflow

| Task                              | Command                                                                                                             |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Add a dependency                  | `uv add trimesh`, then re-enter the shell (direnv does it automatically)                                            |
| Upgrade everything                | `uv lock --upgrade && nix flake update`                                                                             |
| View models in a browser          | `nix run .#viewer` (or `python -m ocp_viewer` in the shell), then `show(part)` from any script                      |
| View in VS Code                   | Install the _OCP CAD Viewer_ extension. Skip its "Quickstart" pip install, because everything is already in the env |
| Run checks (tests in the sandbox) | `nix flake check`                                                                                                   |
| Format Nix                        | `nix fmt`                                                                                                           |
| Throw-away experiments            | `nix develop .#uv` (plain uv-managed `.venv`)                                                                       |

The project itself is installed **editable**, so changing code under `src/`
never triggers a Nix rebuild. Only changes to `pyproject.toml` or `uv.lock` do.
