import pytest
import json
import tempfile
import os
import sys
import threading
import time
from fastapi.testclient import TestClient

# Add the parent directory to the path so we can import app
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import app

@pytest.fixture
def test_config():
    """Test configuration for temporary database file"""
    # Use a temporary file instead of :memory: to avoid threading issues
    import tempfile
    db_fd, db_path = tempfile.mkstemp(suffix='.db')
    os.close(db_fd)  # Close the file descriptor, SQLite will open it
    
    config = {
        "base_url": "https://dev.poleprediction.com",
        "prettyLogging": False,
        "logLevel": 1,
        "jwtSecretVar": "DEV_JWT_SECRET",
        "jwtAlgorithm": "HS256",
        "dbFilepath": db_path,
        "port": 3005,  # Different port for testing
        "debug": True
    }
    
    yield config
    
    # Cleanup: remove the temporary database file
    try:
        os.unlink(db_path)
    except OSError:
        pass

@pytest.fixture
def client(test_config):
    """Create a FastAPI test client"""
    # Configure the app with test config
    app.configure_app(test_config)
    # Return FastAPI test client
    return TestClient(app.app)
