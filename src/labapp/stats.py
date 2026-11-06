"""Pure functions behind the API, kept separate so they are easy to unit test."""

from statistics import mean, median


class InvalidInput(ValueError):
    """Raised when the caller's input can't be turned into numbers."""


MAX_VALUES = 1000


def parse_numbers(raw: str | None) -> list[float]:
    """Parse a comma-separated list like "1, 2.5,3" into floats."""
    if raw is None or not raw.strip():
        raise InvalidInput("query parameter 'numbers' is required, e.g. ?numbers=1,2,3")
    parts = [p.strip() for p in raw.split(",")]
    if len(parts) > MAX_VALUES:
        raise InvalidInput(f"at most {MAX_VALUES} numbers are allowed")
    values = []
    for part in parts:
        try:
            value = float(part)
        except ValueError:
            raise InvalidInput(f"not a number: {part!r}") from None
        if value != value or value in (float("inf"), float("-inf")):
            raise InvalidInput(f"not a finite number: {part!r}")
        values.append(value)
    return values


def summarize(values: list[float]) -> dict[str, float | int]:
    """Count, min, max, mean and median of a non-empty list."""
    if not values:
        raise InvalidInput("at least one number is required")
    return {
        "count": len(values),
        "min": min(values),
        "max": max(values),
        "mean": round(mean(values), 6),
        "median": median(values),
    }
