from fastapi import FastAPI, Request, HTTPException, Depends, Response, status
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
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
from typing import Optional, Dict, Any
import uvicorn
import app_details
import logging
import secrets
from authlib.integrations.requests_client import OAuth2Session

# Global variables that will be set by create_app
app = FastAPI()
password_hasher = argon2.PasswordHasher()

# Make sure the static directory exists
os.makedirs('./static', exist_ok=True)

AUTH_COOKIE_NAME = "auth_token"
AUTH_COOKIE_MAX_DAYS = 360
AUTH_COOKIE_MAX_AGE = AUTH_COOKIE_MAX_DAYS * 24 * 60 * 60  # 360 days in seconds

GOOGLE_CLIENT_ID= os.getenv('GOOGLE_CLIENT_ID')
GOOGLE_CLIENT_SECRET= os.getenv('GOOGLE_CLIENT_SECRET')




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
        raise HTTPException(status_code=500, detail=f"Database integrity error: {str(e)}")
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    finally:
        db.close()

def get_user_id_from_cookie(request: Request) -> Optional[int]:
    """Extract user_id from cookie"""
    token = request.cookies.get(AUTH_COOKIE_NAME)
    if not token:
        return None

    try:
        payload = jwt.decode(token, config["jwtSecret"], algorithms=[config["jwtAlgorithm"]])
        return payload.get('user_id')
    except jwt.PyJWTError:
        return None

def get_current_user_id(request: Request) -> int:
    """FastAPI dependency for authentication"""
    user_id = get_user_id_from_cookie(request)
    if not user_id:
        raise HTTPException(status_code=401, detail="Authentication required")
    return user_id

def require_admin_user(request: Request) -> int:
    """FastAPI dependency for admin authentication"""
    user_id = get_user_id_from_cookie(request)
    if not user_id:
        raise HTTPException(status_code=401, detail="Authentication required")

    with db_transaction() as db:
        query = "SELECT admin FROM users WHERE id = ?"
        result = db.execute(query, (user_id,)).fetchone()

        if not result or result['admin'] != 1:
            raise HTTPException(status_code=403, detail="Admin privileges required")

    return user_id

def verify_password(stored_password, provided_password):
    """Verify password using argon2"""
    try:
        password_hasher.verify(stored_password, provided_password)
        return True
    except argon2.exceptions.VerifyMismatchError:
        return False

def set_auth_cookie(response: Response, user_id: int):
    """Create JWT token and set authentication cookie"""
    # Create JWT token with user_id embedded
    payload = {
        'user_id': user_id,
        'exp': datetime.datetime.now(datetime.UTC) + datetime.timedelta(days=AUTH_COOKIE_MAX_DAYS),
    }
    token = jwt.encode(payload, config["jwtSecret"], algorithm=config["jwtAlgorithm"])

    # Set HTTP-Only secure cookie
    secure_cookie = not config.get('debug', False)  # Don't require HTTPS in debug mode
    response.set_cookie(
        AUTH_COOKIE_NAME,
        token,
        httponly=True,     # Prevents JavaScript access
        secure=secure_cookie,  # Only sent over HTTPS (disabled in debug mode)
        samesite='lax',    # Prevents CSRF but allows for Google OAuth login
        max_age=AUTH_COOKIE_MAX_AGE,
        path='/'           # Available across the entire domain
    )

def get_current_user(db, user_id):
    """Get current user from database"""
    query = "SELECT id, username, fullname, admin FROM users WHERE id = ?"
    user = db.execute(query, (user_id,)).fetchone()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return {
        'id': user['id'],
        'username': user['username'],
        'fullname': user['fullname'],
        'admin': bool(user['admin'])
    }


# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")

# Serve index.html for '/' and any path starting with '/app'
@app.get("/", response_class=HTMLResponse)
@app.get("/app", response_class=HTMLResponse)
@app.get("/app/{path:path}", response_class=HTMLResponse)
def serve_index(request: Request, path: str = None):
    with db_transaction() as db:
        user = None
        user_id = get_user_id_from_cookie(request)
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
        debug_mode = config.get('debug', False)
        user_flags_json = json.dumps(user_flags)
        main_js_src = "/static/main-debug.js" if debug_mode else "/static/main.js"
        main_css_src ="/static/styles.css" if debug_mode else "/static/styles.min.css"
        main_title = f"DEBUG - {app_details.title}" if debug_mode else app_details.title

        index_html = f"""<!DOCTYPE html>
                <html>
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>{main_title}</title>
                    <link rel="icon" type="image/svg" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' width='48' height='48' viewBox='0 0 16 16'><text x='0' y='14'>{app_details.favicon_emoji}</text></svg>"/>

                    <link rel="preconnect" href="https://fonts.googleapis.com">
                    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
                    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">

                    <link rel="stylesheet" href="{main_css_src}">
                    <script src="{main_js_src}"></script>
                </head>
                <body>
                    <h1>{app_details.title}</h1>
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
class UserResponse(BaseModel):
    id: int
    username: str
    fullname: Optional[str]
    email: str
    admin: bool

class AuthResponse(BaseModel):
    success: bool
    message: str
    user: Optional[UserResponse] = None

class LoginRequest(BaseModel):
    username: str
    password: str

@app.post('/api/login')
def login(login_data: LoginRequest, response: Response) -> AuthResponse:
    with db_transaction() as db:
        username = login_data.username
        password = login_data.password

        if not username or not password:
            raise HTTPException(status_code=400, detail="Username and password required")

        # Get user from database
        query = "SELECT id, username, email, fullname, password, admin FROM users WHERE username = ?"
        user = db.execute(query, (username,)).fetchone()

        if not user or not verify_password(user['password'], password):
            raise HTTPException(status_code=401, detail="Invalid credentials")

        # Set authentication cookie
        set_auth_cookie(response, user['id'])

        return AuthResponse(
            success=True,
            message='Login successful',
            user=UserResponse(
                id=user['id'],
                username=user['username'],
                fullname=user['fullname'],
                email=user['email'],
                admin=bool(user['admin'])
            )
        )

class RegisterRequest(BaseModel):
    username: str
    password: str
    email: str
    fullname: Optional[str] = None

@app.post('/api/register')
def register(register_data: RegisterRequest, response: Response) -> AuthResponse:
    with db_transaction() as db:
        username = register_data.username
        password = register_data.password
        email = register_data.email
        fullname = register_data.fullname

        if not username or not password or not email:
            raise HTTPException(status_code=400, detail="Username, password and email required")

        # Check if username already exists
        check_query = "select exists(select 1 from users where username = :username) as user_exists"
        existing_user = db.execute(check_query, {'username': username}).fetchone()

        if existing_user['user_exists']:
            raise HTTPException(status_code=409, detail="Username already exists")

        # Hash the password
        hashed_password = password_hasher.hash(password)

        # Insert new user
        insert_query = """
            insert into users (username, email, fullname, password, admin)
            values (?, ?, ?, ?, ?)
        """
        cursor = db.execute(insert_query, (username, email, fullname, hashed_password, False))
        user_id = cursor.lastrowid

        # Set authentication cookie
        set_auth_cookie(response, user_id)

        return AuthResponse(
            success=True,
            message='Registration successful',
            user=UserResponse(
                id=user_id,
                username=username,
                fullname=fullname,
                email=email,
                admin=False
            )
        )

@app.post('/api/logout')
def logout(response: Response):
    response.delete_cookie(AUTH_COOKIE_NAME, path='/')
    return {'success': True, 'message': 'Logged out successfully'}


# OAuth configuration
GOOGLE_AUTHORIZE_URL = 'https://accounts.google.com/o/oauth2/v2/auth'
GOOGLE_TOKEN_URL = 'https://oauth2.googleapis.com/token'
GOOGLE_USERINFO_URL = 'https://www.googleapis.com/oauth2/v2/userinfo'

# Store OAuth states temporarily (in production, use Redis or database)
oauth_states = {}

@app.get('/api/auth/google/login')
def google_oauth_login():
    """Initiate Google OAuth flow"""
    state = secrets.token_urlsafe(32)

    oauth = OAuth2Session(
        GOOGLE_CLIENT_ID,
        redirect_uri=f"{config['base_url']}/api/auth/google/callback",
        scope='openid email profile'
    )

    authorization_url, _ = oauth.create_authorization_url(
        GOOGLE_AUTHORIZE_URL,
        state=state
    )

    print(f"AND THE AUTH URL IS: {authorization_url}")

    # Store state temporarily (use Redis/database in production)
    oauth_states[state] = True

    # Return the URL for frontend to redirect to
    # return {'authorization_url': authorization_url}
    return RedirectResponse(url=authorization_url)

@app.get('/api/auth/google/callback')
def google_oauth_callback(request: Request, response: Response, code: Optional[str] = None, state: Optional[str] = None, error: Optional[str] = None):
    """Handle Google OAuth callback"""

    if error:
        raise HTTPException(status_code=400, detail=f'OAuth error: {error}')

    if not code or not state or state not in oauth_states:
        raise HTTPException(status_code=400, detail='Invalid OAuth callback')

    # Clean up state
    del oauth_states[state]

    try:
        # Exchange code for token
        oauth = OAuth2Session(
            GOOGLE_CLIENT_ID,
            redirect_uri=f"{config['base_url']}/api/auth/google/callback"
        )

        token = oauth.fetch_token(
            GOOGLE_TOKEN_URL,
            code=code,
            client_secret=GOOGLE_CLIENT_SECRET
        )

        # Get user info from Google
        resp = oauth.get(GOOGLE_USERINFO_URL)
        user_info = resp.json()

        # Process the OAuth login
        oauth_result = process_oauth_login('google', user_info)

        if not oauth_result["success"]:
            return RedirectResponse(url=f"{config['base_url']}#/login?error=oauth_failed", status_code=303)

        user_id = oauth_result["user"]["id"]

        redirect = RedirectResponse(url=f"{config['base_url']}#/", status_code=303)
        set_auth_cookie(redirect, user_id)   # <-- set cookie on the redirect response
        return redirect

    except Exception as e:
        logging.error(f"OAuth error: {repr(e)}")
        raise HTTPException(status_code=500, detail='OAuth authentication failed')

def process_oauth_login(provider, user_info):
    """Process OAuth login and create/update user"""
    with db_transaction() as db:
        provider_user_id = user_info.get('id')
        email = user_info.get('email')
        display_name = user_info.get('name')
        
        if not provider_user_id or not email:
            return {'success': False, 'message': 'Incomplete user information from OAuth provider'}
        
        # Check if OAuth account already exists
        oauth_query = """
            select u.id, u.username, u.email, u.fullname, u.admin 
            from users u
            join user_oauth_accounts uoa on u.id = uoa.user_id
            where uoa.provider = :provider and uoa.provider_user_id = :provider_user_id
        """
        
        existing_oauth_user = db.execute(oauth_query, {
            "provider": provider,
            "provider_user_id": provider_user_id
        }).fetchone()
        
        if existing_oauth_user:
            # User exists with this OAuth account
            user = existing_oauth_user
        else:
            # Check if user exists by email
            email_query = "select id, username, email, fullname, admin from users where email = :email"
            existing_email_user = db.execute(email_query, {"email": email}).fetchone()
            
            if existing_email_user:
                # Link OAuth account to existing user
                user = existing_email_user
                db.execute("""
                    insert into user_oauth_accounts (user_id, provider, provider_user_id, email)
                    values (:user_id, :provider, :provider_user_id, :email)
                """, {
                    "user_id": user['id'],
                    "provider": provider,
                    "provider_user_id": provider_user_id,
                    "email": email
                })
            else:
                # Create new user
                insert_user_query = """
                    insert into users (email, fullname, username, admin)
                    values (:email, :fullname, :username, false)
                    returning id, username, email, fullname, admin
                """
                
                # Generate username from email if not provided
                username = email.split('@')[0]
                # Handle username conflicts by appending numbers
                base_username = username
                counter = 1
                while True:
                    check_username = db.execute("select id from users where username = :username", 
                                              {"username": username}).fetchone()
                    if not check_username:
                        break
                    username = f"{base_username}{counter}"
                    counter += 1
                
                user = db.execute(insert_user_query, {
                    "email": email,
                    "fullname": display_name or email,
                    "username": username
                }).fetchone()
                
                # Create OAuth account link
                db.execute("""
                    insert into user_oauth_accounts (user_id, provider, provider_user_id, email)
                    values (:user_id, :provider, :provider_user_id, :email)
                """, {
                    "user_id": user['id'],
                    "provider": provider,
                    "provider_user_id": provider_user_id,
                    "email": email
                })

        return {
            'success': True, 
            'message': 'OAuth login successful',
            'user': {
                'id': user['id'],
                'username': user['username'],
                'fullname': user['fullname'],
                'email': user['email'],
                'admin': bool(user['admin'])
            }
        }



@app.get('/api/me')
def get_me(user_id: int = Depends(get_current_user_id)):
    with db_transaction() as db:
        return get_current_user(db, user_id)

class ProfileUpdateRequest(BaseModel):
    fullname: str

@app.post('/api/profile')
def update_profile(profile_data: ProfileUpdateRequest, user_id: int = Depends(get_current_user_id)):
    with db_transaction() as db:
        fullname = profile_data.fullname

        if fullname is None:
            raise HTTPException(status_code=400, detail="Full name is required")

        # Update user profile
        query = "UPDATE users SET fullname = ? WHERE id = ?"
        db.execute(query, (fullname, user_id))

        # Return updated user data
        return get_current_user(db, user_id)


class FeedbackRequest(BaseModel):
    comments: str
    email: Optional[str] = None

@app.post('/api/feedback')
def submit_feedback(feedback_data: FeedbackRequest, request: Request):
    """Submit user feedback.

    Accepts feedback from both authenticated and anonymous users.
    """
    with db_transaction() as db:
        comments = feedback_data.comments.strip()
        if not comments:
            raise HTTPException(status_code=400, detail="Comments are required and must be a non-empty string")

        if len(comments) > 5000:  # Reasonable length limit
            raise HTTPException(status_code=400, detail="Comments must be 5000 characters or less")

        # Optional email validation
        email = None
        if feedback_data.email:
            email = feedback_data.email.strip()
            if len(email) > 255:  # Standard email field length
                raise HTTPException(status_code=400, detail="Email must be 255 characters or less")
            if not email:  # Empty string becomes None
                email = None

        # Get user ID if authenticated (optional)
        user_id = get_user_id_from_cookie(request)

        # Get user agent and IP address from request
        user_agent = request.headers.get('user-agent', '')
        # Get real IP address, accounting for proxies
        ip_address = (request.headers.get('x-forwarded-for') or
                     request.headers.get('x-real-ip') or
                     request.client.host)

        # If X-Forwarded-For contains multiple IPs, take the first one
        if ip_address and ',' in ip_address:
            ip_address = ip_address.split(',')[0].strip()

        # Insert feedback into database
        insert_query = """
            insert into user_feedback (user_id, email, comments, user_agent, ip_address, status)
            values (:user_id, :email, :comments, :user_agent, :ip_address, :status)
        """

        cursor = db.execute(insert_query, {
            "user_id": user_id,
            "email": email,
            "comments": comments,
            "user_agent": user_agent,
            "ip_address": ip_address,
            "status": "new"
        })

        feedback_id = cursor.lastrowid

        return {
            'success': True,
            'message': 'Feedback submitted successfully',
            'feedback_id': feedback_id
        }



@app.get('/api/protected-resource')
def protected_resource(user_id: int = Depends(get_current_user_id)):
    return {'message': f'Hello, authenticated user {user_id}!'}

def configure_app(config_dict):
    """Configure JWT and logging after config is loaded."""
    global config
    config = config_dict

    config['jwtSecret'] = os.getenv(config['jwtSecretVar'])
    
    # Configure logging based on config
    if config.get('prettyLogging', False):
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
        migration_files = [
            'sql/migrations/001-create-users-table.sql',
            'sql/migrations/002-add-oauth-accounts.sql',
            'sql/migrations/003-user-feedback.sql',
        ]
        for migration_file in migration_files:
            with open(migration_file, 'r') as f:
                sql_content = f.read()
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
    uvicorn.run(
        app,
        host='localhost',
        port=config.get('port', 8080),
        log_level="debug" if config.get('debug', False) else "info"
    )
