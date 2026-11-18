"""Example model: a filleted mounting plate with counterbored holes.

Run it with `python -m cad.bracket` — it exports STEP/STL to ./out and,
if a viewer is running (VS Code OCP CAD Viewer or `nix run .#viewer`), shows it.
"""

from pathlib import Path

from build123d import *


def make_bracket(
    length: float = 80, width: float = 40, thickness: float = 6, hole_d: float = 5
) -> Part:
    with BuildPart() as bracket:
        Box(length, width, thickness)
        fillet(bracket.edges().filter_by(Axis.Z), radius=4)
        with Locations(bracket.faces().sort_by(Axis.Z)[-1]):
            with GridLocations(length - 20, width - 20, 2, 2):
                CounterBoreHole(hole_d / 2, hole_d * 0.9, thickness / 3)
    return bracket.part


def main() -> None:
    part = make_bracket()
    out = Path("out")
    out.mkdir(exist_ok=True)
    export_step(part, out / "bracket.step")
    export_stl(part, out / "bracket.stl")
    print(f"volume = {part.volume:.1f} mm³ → {out}/bracket.{{step,stl}}")

    if viewer_running():
        from ocp_vscode import show

        show(part)


def viewer_running(port: int = 3939) -> bool:
    """True if an OCP CAD Viewer (VS Code or `nix run .#viewer`) listens on `port`."""
    import socket

    try:
        import ocp_vscode  # noqa: F401  (dev dependency only)

        with socket.create_connection(("127.0.0.1", port), timeout=0.2):
            return True
    except (ImportError, OSError):
        return False


if __name__ == "__main__":
    main()
