"""Flask app factory and routes."""

import os
import socket
from importlib.metadata import PackageNotFoundError, version

from flask import Flask, jsonify, request

from labapp.stats import InvalidInput, parse_numbers, summarize


def app_version() -> str:
    """Version of the installed package (what the build stamped into it)."""
    try:
        return version("labapp")
    except PackageNotFoundError:
        return "0.0.0+unknown"


def create_app() -> Flask:
    app = Flask(__name__)

    @app.get("/health")
    def health():
        # A deploy's health check reads this. LABAPP_FORCE_UNHEALTHY=1 makes it fail on purpose,
        # for practicing automatic rollback.
        if os.environ.get("LABAPP_FORCE_UNHEALTHY") == "1":
            return jsonify(status="unhealthy", version=app_version()), 500
        return jsonify(status="ok", version=app_version(), host=socket.gethostname())

    @app.get("/api/v1/stats")
    def stats():
        try:
            values = parse_numbers(request.args.get("numbers"))
            return jsonify(summarize(values))
        except InvalidInput as exc:
            return jsonify(error=str(exc)), 400

    return app
