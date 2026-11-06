import pytest

from labapp.stats import MAX_VALUES, InvalidInput, parse_numbers, summarize


def test_parse_numbers_accepts_spaces_and_decimals():
    assert parse_numbers(" 1, 2.5 ,3") == [1.0, 2.5, 3.0]


@pytest.mark.parametrize("raw", [None, "", "   "])
def test_parse_numbers_requires_input(raw):
    with pytest.raises(InvalidInput, match="required"):
        parse_numbers(raw)


@pytest.mark.parametrize("raw", ["1,abc", "1,,2", "nan", "inf"])
def test_parse_numbers_rejects_bad_values(raw):
    with pytest.raises(InvalidInput):
        parse_numbers(raw)


def test_parse_numbers_limits_size():
    with pytest.raises(InvalidInput, match="at most"):
        parse_numbers(",".join(["1"] * (MAX_VALUES + 1)))


def test_summarize():
    assert summarize([3, 1, 2, 10]) == {
        "count": 4,
        "min": 1,
        "max": 10,
        "mean": 4.0,
        "median": 2.5,
    }


def test_summarize_single_value():
    assert summarize([7.0])["median"] == 7.0


def test_summarize_rejects_empty():
    with pytest.raises(InvalidInput):
        summarize([])


@pytest.mark.slow
def test_summarize_large_input_is_stable():
    values = [float(i) for i in range(MAX_VALUES)] * 200
    result = summarize(values)
    assert result["count"] == MAX_VALUES * 200
    assert result["mean"] == pytest.approx((MAX_VALUES - 1) / 2)
