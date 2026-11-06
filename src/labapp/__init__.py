"""labapp: a small HTTP service to build, test, package and deploy with Jenkins."""

from labapp.app import create_app

__all__ = ["create_app"]
