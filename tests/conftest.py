import pytest
import json
import tempfile
import os
import sys
import threading
import time
import requests

# Add the parent directory to the path so we can import app
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import app
import bottle

@pytest.fixture
def test_config():
    """Test configuration for temporary database file"""
    # Use a temporary file instead of :memory: to avoid threading issues
    import tempfile
    db_fd, db_path = tempfile.mkstemp(suffix='.db')
    os.close(db_fd)  # Close the file descriptor, SQLite will open it
    
    config = {
        "prettyLogging": False,
        "logLevel": 1,
        "jwtSecret": "test-secret-key-for-testing-only",
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
def test_app(test_config):
    """Create a test app instance with in-memory database"""
    # Each test gets a fresh in-memory database
    app.configure_app(test_config)
    # The database tables should be created by init_test_database in create_app
    return app.app

@pytest.fixture
def test_server(test_app, test_config):
    """Start a test server in a separate thread"""
    
    # Create server thread
    server_thread = None
    server = None
    
    def run_server():
        nonlocal server
        # Use a different bottle server for testing
        from wsgiref.simple_server import make_server
        server = make_server('localhost', test_config['port'], test_app)
        server.serve_forever()
    
    server_thread = threading.Thread(target=run_server, daemon=True)
    server_thread.start()
    
    # Wait for server to start
    time.sleep(0.2)
    
    yield f"http://localhost:{test_config['port']}"
    
    # Cleanup
    if server:
        server.shutdown()

@pytest.fixture
def client(test_server):
    """Create a test client using requests library"""
    class TestClient:
        def __init__(self, base_url):
            self.base_url = base_url
            self.session = requests.Session()
            
        def post(self, path, json=None, headers=None):
            """Make a POST request"""
            url = self.base_url + path
            return self.session.post(url, json=json, headers=headers or {})
            
        def get(self, path, headers=None):
            """Make a GET request"""
            url = self.base_url + path
            return self.session.get(url, headers=headers or {})
    
    return TestClient(test_server)
