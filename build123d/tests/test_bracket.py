from build123d import export_step, import_step

from cad.bracket import make_bracket


def test_bracket_is_valid_solid():
    part = make_bracket()
    assert part.is_valid
    assert len(part.solids()) == 1
    # Box minus four counterbored holes, so strictly less than the bounding volume
    assert 0 < part.volume < 80 * 40 * 6


def test_step_round_trip(tmp_path):
    part = make_bracket()
    path = tmp_path / "bracket.step"
    export_step(part, path)
    assert abs(import_step(path).volume - part.volume) < 1e-3
