import pytest
import os
import requests
from src import map_handler

def test_fetch_route_success(monkeypatch):
    monkeypatch.setattr(os, "getenv", lambda key: "fake_api_key")

    class MockResponse:
        status_code = 200

        def json(self):
            return {"routes": [{"sections": [{"polyline": "BFoz5xJ67i1B1B7PzIhaxL7Y"}]}]}

        def raise_for_status(self):
            pass

    def mock_get(*args, **kwargs):
        return MockResponse()

    monkeypatch.setattr(requests, "get", mock_get)

    result = map_handler.fetch_route_from_api("53.3441,-6.2573", "53.3430,-6.2672")
    assert result is not None  
