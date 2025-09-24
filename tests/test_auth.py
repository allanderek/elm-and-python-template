import pytest
import json
import app


class TestAuthentication:
    """Test cases for authentication endpoints"""
    
    def test_register_user_success(self, client):
        """Test successful user registration"""
        user_data = {
            "username": "testuser",
            "password": "testpassword123",
            "email": "test@example.com",
            "fullname": "Test User"
        }
        
        response = client.post('/api/register', json=user_data)
        
        assert response.status_code == 200
        response_data = response.json()
        assert response_data['success'] is True
        assert response_data['message'] == 'Registration successful'
        assert response_data['user']['username'] == 'testuser'
        assert response_data['user']['email'] == 'test@example.com'
        assert response_data['user']['fullname'] == 'Test User'
        assert response_data['user']['admin'] is False
        assert 'id' in response_data['user']
    
    def test_register_user_missing_fields(self, client):
        """Test registration with missing required fields"""
        # Missing password
        user_data = {
            "username": "testuser",
            "email": "test@example.com"
        }

        response = client.post('/api/register', json=user_data)

        assert response.status_code == 422  # FastAPI returns 422 for validation errors
        response_data = response.json()
        assert 'detail' in response_data  # FastAPI uses 'detail' for error messages
    
    def test_register_duplicate_username(self, client):
        """Test registration with existing username"""
        user_data = {
            "username": "testuser",
            "password": "testpassword123",
            "email": "test@example.com",
            "fullname": "Test User"
        }
        
        # Register user first time
        response1 = client.post('/api/register', json=user_data)
        assert response1.status_code == 200
        
        # Try to register same username again
        user_data2 = {
            "username": "testuser",  # Same username
            "password": "differentpassword",
            "email": "different@example.com",
            "fullname": "Different User"
        }
        
        response2 = client.post('/api/register', json=user_data2)
        
        assert response2.status_code == 409
        response_data = response2.json()
        assert 'detail' in response_data
        assert 'already exists' in response_data['detail'].lower()
    
    def test_login_success(self, client):
        """Test successful login"""
        # First register a user
        user_data = {
            "username": "testuser",
            "password": "testpassword123",
            "email": "test@example.com",
            "fullname": "Test User"
        }
        
        register_response = client.post('/api/register', json=user_data)
        assert register_response.status_code == 200
        
        # Now try to login
        login_data = {
            "username": "testuser",
            "password": "testpassword123"
        }
        
        response = client.post('/api/login', json=login_data)
        
        assert response.status_code == 200
        response_data = response.json()
        assert response_data['success'] is True
        assert response_data['message'] == 'Login successful'
        assert response_data['user']['username'] == 'testuser'
        assert response_data['user']['email'] == 'test@example.com'
        assert 'id' in response_data['user']
    
    def test_login_invalid_password(self, client):
        """Test login with incorrect password"""
        # First register a user
        user_data = {
            "username": "testuser",
            "password": "testpassword123",
            "email": "test@example.com",
            "fullname": "Test User"
        }
        
        register_response = client.post('/api/register', json=user_data)
        assert register_response.status_code == 200
        
        # Try to login with wrong password
        login_data = {
            "username": "testuser",
            "password": "wrongpassword"
        }
        
        response = client.post('/api/login', json=login_data)
        
        assert response.status_code == 401
        response_data = response.json()
        assert 'detail' in response_data
        assert 'invalid credentials' in response_data['detail'].lower()
    
    def test_login_nonexistent_user(self, client):
        """Test login with non-existent username"""
        login_data = {
            "username": "nonexistentuser",
            "password": "somepassword"
        }
        
        response = client.post('/api/login', json=login_data)
        
        assert response.status_code == 401
        response_data = response.json()
        assert 'detail' in response_data
        assert 'invalid credentials' in response_data['detail'].lower()
    
    def test_login_missing_fields(self, client):
        """Test login with missing required fields"""
        # Missing password
        login_data = {
            "username": "testuser"
        }

        response = client.post('/api/login', json=login_data)

        assert response.status_code == 422  # FastAPI returns 422 for validation errors
        response_data = response.json()
        assert 'detail' in response_data  # FastAPI uses 'detail' for error messages
    
    def test_logout_success(self, client):
        """Test successful logout"""
        response = client.post('/api/logout')
        
        assert response.status_code == 200
        response_data = response.json()
        assert response_data['success'] is True
        assert response_data['message'] == 'Logged out successfully'
    
    def test_password_hashing(self, client):
        """Test that passwords are properly hashed"""
        user_data = {
            "username": "testuser",
            "password": "testpassword123",
            "email": "test@example.com",
            "fullname": "Test User"
        }
        
        # Register user
        response = client.post('/api/register', json=user_data)
        assert response.status_code == 200
        
        # Verify we can't login with the hash directly
        # This tests that the password is actually hashed
        with app.db_transaction() as db:
            query = "SELECT password FROM users WHERE username = ?"
            user = db.execute(query, ("testuser",)).fetchone()
            stored_hash = user['password']
            
            # The stored password should not be the plain password
            assert stored_hash != "testpassword123"
            
            # The stored password should be an argon2 hash
            assert stored_hash.startswith("$argon2")
    
    def test_protected_route_without_auth(self, client):
        """Test accessing protected route without authentication"""
        response = client.get('/api/me')

        assert response.status_code == 401
        response_data = response.json()
        assert 'detail' in response_data
        assert 'authentication required' in response_data['detail'].lower()


class TestPasswordSecurity:
    """Test password security features"""
    
    def test_password_verification(self):
        """Test password verification function directly"""
        # Hash a password
        test_password = "mysecretpassword"
        hashed = app.password_hasher.hash(test_password)
        
        # Test correct password verification
        assert app.verify_password(hashed, test_password) is True
        
        # Test incorrect password verification  
        assert app.verify_password(hashed, "wrongpassword") is False
        
        # Test with empty password
        assert app.verify_password(hashed, "") is False
    
    def test_password_hash_format(self):
        """Test that password hashes use proper argon2 format"""
        test_password = "testpassword123"
        hashed = app.password_hasher.hash(test_password)
        
        # Argon2 hashes should start with $argon2
        assert hashed.startswith("$argon2")
        
        # Should contain the expected number of $ separators
        assert hashed.count("$") >= 4