import pytest

from labapp import create_app


@pytest.fixture
def client():
    app = create_app()
    app.config.update(TESTING=True)
    return app.test_client()


def test_health_ok(client):
    res = client.get("/health")
    assert res.status_code == 200
    body = res.get_json()
    assert body["status"] == "ok"
    assert body["version"]


def test_health_can_be_forced_unhealthy(client, monkeypatch):
    monkeypatch.setenv("LABAPP_FORCE_UNHEALTHY", "1")
    res = client.get("/health")
    assert res.status_code == 500
    assert res.get_json()["status"] == "unhealthy"


def test_stats(client):
    res = client.get("/api/v1/stats?numbers=1,2,3,4")
    assert res.status_code == 200
    assert res.get_json() == {"count": 4, "min": 1.0, "max": 4.0, "mean": 2.5, "median": 2.5}


@pytest.mark.parametrize("query", ["", "?numbers=", "?numbers=1,x"])
def test_stats_bad_input_is_400(client, query):
    res = client.get(f"/api/v1/stats{query}")
    assert res.status_code == 400
    assert "error" in res.get_json()


def test_unknown_route_is_404(client):
    assert client.get("/nope").status_code == 404
