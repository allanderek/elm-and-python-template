import bottle
import argon2
import os
import jwt
import contextlib
import datetime
import hashlib
import binascii
import re
import json
import sys
from functools import wraps
import sqlite3
import inspect
import base64
import hmac

# Global variables that will be set by create_app
app = bottle.Bottle()
config = {
  "prettyLogging": True,
  "logLevel": -1,
  "jwtSecret": "34edf35d-4b7b-4b7b-8b7b-4b7b4b7b4b7b",
  "dbFilepath": "debug.db",
  "port": 3003,
  "debug": True
  }
password_hasher = argon2.PasswordHasher()

# Make sure the static directory exists
os.makedirs('./static', exist_ok=True)

AUTH_COOKIE_NAME = "auth_token"
AUTH_COOKIE_MAX_DAYS = 360
AUTH_COOKIE_MAX_AGE = AUTH_COOKIE_MAX_DAYS * 24 * 60 * 60  # 360 days in seconds



@contextlib.contextmanager
def db_transaction():
    """Context manager for SQLite database transactions."""
    db = sqlite3.connect(config['dbFilepath'])
    db.row_factory = sqlite3.Row  # Enable dictionary-like access

    try:
        yield db
        db.commit()
    except sqlite3.IntegrityError as e:
        db.rollback()
        bottle.response.status = 500
        raise bottle.HTTPError(500, f"Database integrity error: {str(e)}")
    except bottle.HTTPError:
        db.rollback()
        raise
    except bottle.HTTPResponse as e:
        db.commit()
        raise
    except Exception as e:
        db.rollback()
        bottle.response.status = 500
        raise bottle.HTTPError(500, f"Database error: {str(e)}")
    finally:
        db.close()

def require_auth(func):
    """Authentication decorator"""
    @wraps(func)
    def wrapper(*args, **kwargs):
        user_id = get_user_id_from_cookie()
        if not user_id:
            bottle.response.status = 401
            return {"error": "Authentication required"}
        kwargs['user_id'] = user_id
        return func(*args, **kwargs)
    return wrapper

def require_admin(db):
    """Check if user is admin (no longer a decorator)"""
    user_id = get_user_id_from_cookie()
    if not user_id:
        bottle.response.status = 401
        return {"error": "Authentication required"}
            
    if not db:
        bottle.response.status = 500
        return {"error": "Database connection error"}
            
    # Check if user is admin
    query = "SELECT admin FROM users WHERE id = ?"
    result = db.execute(query, (user_id,)).fetchone()
    
    if not result or result['admin'] != 1:
        bottle.response.status = 403
        return {"error": "Admin privileges required"}

    return user_id

def get_user_id_from_cookie():
    """Extract user_id from cookie"""
    token = bottle.request.get_cookie(AUTH_COOKIE_NAME)
    if not token:
        return None
    
    try:
        payload = jwt.decode(token, config["jwtSecret"], algorithms=[config["jwtAlgorithm"]])
        return payload.get('user_id')
    except jwt.PyJWTError:
        return None

def verify_password(stored_password, provided_password):
    """Verify password using argon2"""
    try:
        password_hasher.verify(stored_password, provided_password)
        return True
    except argon2.exceptions.VerifyMismatchError:
        return False

def get_current_user(db, user_id):
    """Get current user from database"""
    query = "SELECT id, username, fullname, admin FROM users WHERE id = ?"
    user = db.execute(query, (user_id,)).fetchone()
    
    if not user:
        bottle.response.status = 404
        return {'error': 'User not found'}
    
    return {
        'id': user['id'],
        'username': user['username'],
        'fullname': user['fullname'],
        'admin': bool(user['admin'])
    }


# Serve static files from the 'static' directory
@app.route('/static/<filepath:path>')
def serve_static(filepath):
    return bottle.static_file(filepath, root='./static')

# Serve index.html for '/' and any path starting with '/app'
@app.route('/')
@app.route('/app')
@app.route('/app/<path:path>')
def serve_index(path=None):
    with db_transaction() as db:
        user = None
        user_id = get_user_id_from_cookie()
        if user_id:
            query = "SELECT id, username, fullname, password, admin FROM users WHERE id = ?"
            user = db.execute(query, (user_id,)).fetchone()

        user_flags = {}
        if user:
            user_flags = {
                "id": user['id'],
                "username": user['username'],
                "fullname": user['fullname'],
                "admin": bool(user['admin'])
            }
        user_flags_json = json.dumps(user_flags)
        main_js_src = "/static/main-debug.js" if config.get('debug', False) else "/static/main.js" 
        main_css_src ="/static/styles.css" if config.get('debug', False) else "/static/styles.min.css"

        index_html = f"""<!DOCTYPE html>
                <html>
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>My application</title>
                    <link rel="icon" type="image/svg" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' width='48' height='48' viewBox='0 0 16 16'><text x='0' y='14'>⚽</text></svg>"/>

                    <link rel="preconnect" href="https://fonts.googleapis.com">
                    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
                    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">

                    <link rel="stylesheet" href="{main_css_src}">
                    <script src="{main_js_src}"></script>
                </head>
                <body>
                    <h1>My application</h1>
                    <script> 
                        const safeLocalStorage = {{
                              getItem(key) {{
                                try {{
                                  return localStorage.getItem(key);
                                }} catch(e) {{
                                  return null;
                                }}
                              }},
                              setItem(key, value) {{
                                try {{
                                  localStorage.setItem(key, value);
                                }} catch(e) {{
                                  // 
                                }}
                              }},
                              removeItem(key, value) {{
                                try {{
                                  localStorage.removeItem(key, value);
                                }} catch(e) {{
                                  // 
                                }}
                              }}
                        }};

                        const user_flags = {user_flags_json};
                        const flags = {{ "flags" : {{ "now": Date.now(), "user": user_flags }} }}; 
                        var app = Elm.Main.init(flags); 


                        app.ports.set_local_storage.subscribe(function (args) {{ 
                            safeLocalStorage.setItem(args.key, JSON.stringify(args.value)); 
                        }});

                        app.ports.clear_local_storage.subscribe(function (args) {{ 
                            safeLocalStorage.removeItem(args); 
                        }});


                        app.ports.native_alert.subscribe(function (message) {{ 
                            alert(message); 
                        }});

                        window.addEventListener('storage', function(event) {{
                            console.log('local storage event');
                            console.log(event);
                            if (event.key === 'user') {{
                                app.ports.local_storage_changed.send(
                                    {{ key: event.key,
                                      newValue: JSON.parse(event.newValue) }}
                                );
                            }}
                        }});
                    </script>
                </body>
                </html>"""
        return index_html

# Authentication routes
@app.route('/api/login', method='POST')
def login():
    with db_transaction() as db:
        data = bottle.request.json
        
        username = data.get('username')
        password = data.get('password')
        
        if not username or not password:
            bottle.response.status = 400
            return {'success': False, 'message': 'Username and password required'}
        
        # Get user from database
        query = "SELECT id, username, email, fullname, password, admin FROM users WHERE username = ?"
        user = db.execute(query, (username,)).fetchone()
        
        if not user or not verify_password(user['password'], password):
            bottle.response.status = 401
            return {'success': False, 'message': 'Invalid credentials'}
        
        # Create JWT token with user_id embedded
        payload = {
            'user_id': user['id'],
            'exp': datetime.datetime.now(datetime.UTC) + datetime.timedelta(days=AUTH_COOKIE_MAX_DAYS),
        }
        token = jwt.encode(payload, config["jwtSecret"], algorithm=config["jwtAlgorithm"])
        
        # Set HTTP-Only secure cookie
        secure_cookie = not config.get('debug', False)  # Don't require HTTPS in debug mode
        bottle.response.set_cookie(
            AUTH_COOKIE_NAME, 
            token,
            httponly=True,     # Prevents JavaScript access
            secure=secure_cookie,  # Only sent over HTTPS (disabled in debug mode)
            samesite='strict', # Prevents CSRF
            max_age=AUTH_COOKIE_MAX_AGE,
            path='/'           # Available across the entire domain
        )
        
        return {
            'success': True, 
            'message': 'Login successful',
            'user': {
                'id': user['id'],
                'username': user['username'],
                'fullname': user['fullname'],
                'email': user['email'],
                'admin': bool(user['admin'])
            }
        }

@app.route('/api/register', method='POST')
def register():
    with db_transaction() as db:
        data = bottle.request.json
        
        username = data.get('username')
        password = data.get('password')
        email = data.get('email')
        fullname = data.get('fullname')
        
        if not username or not password or not email:
            bottle.response.status = 400
            return {'success': False, 'message': 'Username, password and email required'}

        # Check if username already exists
        check_query = "select exists(select 1 from users where username = :username) as user_exists"
        existing_user = db.execute(check_query, {'username': username}).fetchone()

        if existing_user['user_exists']:
            bottle.response.status = 409
            return {'success': False, 'message': 'Username already exists'}
        
        # Hash the password
        hashed_password = password_hasher.hash(password)
        
        # Insert new user
        insert_query = """
            insert into users (username, email, fullname, password, admin) 
            values (?, ?, ?, ?, ?)
        """
        cursor = db.execute(insert_query, (username, email, fullname, hashed_password, False))
        user_id = cursor.lastrowid
        
        # Create JWT token for the new user
        payload = {
            'user_id': user_id,
            'exp': datetime.datetime.now(datetime.UTC) + datetime.timedelta(days=AUTH_COOKIE_MAX_DAYS),
        }
        token = jwt.encode(payload, config["jwtSecret"], algorithm=config["jwtAlgorithm"])
        
        # Set HTTP-Only secure cookie
        secure_cookie = not config.get('debug', False)
        bottle.response.set_cookie(
            AUTH_COOKIE_NAME, 
            token,
            httponly=True,
            secure=secure_cookie,
            samesite='strict',
            max_age=AUTH_COOKIE_MAX_AGE,
            path='/'
        )
        
        return {
            'success': True, 
            'message': 'Registration successful',
            'user': {
                'id': user_id,
                'username': username,
                'fullname': fullname,
                'email': email,
                'admin': False
            }
        }

@app.route('/api/logout', method='POST')
def logout():
    bottle.response.delete_cookie(AUTH_COOKIE_NAME, path='/')
    return {'success': True, 'message': 'Logged out successfully'}

@app.route('/api/me', method='GET')
@require_auth
def get_me(user_id):
    with db_transaction() as db:
        return get_current_user(db, user_id)

@app.route('/api/profile', method='POST')
@require_auth
def update_profile(user_id):
    with db_transaction() as db:
        data = bottle.request.json
        
        fullname = data.get('fullname')
        
        if fullname is None:
            bottle.response.status = 400
            return {'error': 'Full name is required'}
        
        # Update user profile
        query = "UPDATE users SET fullname = ? WHERE id = ?"
        db.execute(query, (fullname, user_id))
        
        # Return updated user data
        return get_current_user(db, user_id)

@app.route('/api/protected-resource', methods=['GET'])
@require_auth
def protected_resource(user_id):
    return {'message': f'Hello, authenticated user {user_id}!'}


def configure_app(config_dict):
    """Configure JWT and logging after config is loaded."""
    global config
    config = config_dict
    config["jwtAlgorithm"] = "HS256"
    
    # Configure logging based on config
    if config.get('prettyLogging', False):
        import logging
        logging.basicConfig(
            level=logging.DEBUG if config.get('logLevel', 0) <= 0 else logging.INFO,
            format='%(asctime)s [%(levelname)s] %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        logger = logging.getLogger(__name__)
        logger.info(f"Starting application with config: {config['dbFilepath']}")

    # Initialize database schema if using in-memory database, temp file, or if it doesn't exist  
    needs_init = (config['dbFilepath'] == ':memory:' or 
                  not os.path.exists(config['dbFilepath']) or
                  '/tmp/' in config['dbFilepath'])  # Force init for temp files
    
    if needs_init:
        init_test_database()


def init_test_database():
    """Initialize database schema by executing SQL migration files."""
    with db_transaction() as db:
        # Execute the create users table migration
        migration_file = 'sql/migrations/create-users-table.sql'
        with open(migration_file, 'r') as f:
            sql_content = f.read()
        
        # Execute all SQL statements in the file
        db.executescript(sql_content)

if __name__ == '__main__':

    if len(sys.argv) < 2:
        print("Usage: python app.py <config_file.json>")
        sys.exit(1)
    
    config_file = sys.argv[1]
    try:
        with open(config_file, 'r') as f:
            config_dict = json.load(f)
    except Exception as e:
        print(f"Error loading configuration: {e}")
        sys.exit(1)

    configure_app(config_dict)
    
    # Run the application with settings from config
    bottle.run(
        app, 
        host='localhost', 
        port=config.get('port', 8080), 
        debug=config.get('debug', False)
    )
