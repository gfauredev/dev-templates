# Nushell ⇄ direnv integration. Add to config.nu (`config nu`), or
# `source /path/to/direnv.nu` from it.
# (Home Manager users: `programs.direnv.enableNushellIntegration = true;` instead.)
$env.config.hooks.pre_prompt = (
  $env.config.hooks.pre_prompt? | default [] | append {||
    if (which direnv | is-empty) { return }
    let diff = (direnv export json | from json | default {})
    if ($diff | is-empty) { return }
    # direnv marks variables to remove (on leaving a dir) with null
    let gone = ($diff | transpose k v | where v == null | get k)
    if ($gone | is-not-empty) { hide-env --ignore-errors ...$gone }
    $diff | reject ...$gone | load-env
    if ($env.PATH | describe) == "string" {
      $env.PATH = ($env.PATH | split row (char esep))
    }
  }
)

# Without direnv: `dev`, `dev .#bun`, ... drops you into the flake shell, inside Nushell.
def --wrapped dev [...args] { nix develop ...$args --command nu }

