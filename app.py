import os
from flask import Flask, render_template, request, redirect, url_for, flash, session
from forms import RegistrationForm
from models import db, bcrypt, User
from config import Config
from prometheus_client import Counter, generate_latest, make_wsgi_app
from prometheus_client.exposition import basic_auth_handler



app = Flask(__name__)

# Create a metric to track requests
REQUEST_COUNT = Counter('flask_requests_total', 'Total number of requests')
PAGE_VIEWS = Counter("flask_page_views", "Count of page views", ["endpoint"])


app.secret_key = os.getenv('SECRET_KEY', 'default_secret_key')

app.config.from_object(Config)

db.init_app(app)
bcrypt.init_app(app)

@app.before_request
def create_tables():
    db.create_all()


@app.route('/register', methods=['GET', 'POST'])
def register():
    form = RegistrationForm()
    if form.validate_on_submit():
        hashed_password = bcrypt.generate_password_hash(form.password.data).decode('utf-8')
        user = User(username=form.username.data,password=hashed_password)
        db.session.add(user)
        db.session.commit()
        flash('Your account has been created! You can now log in.', 'success')
        return redirect(url_for('login'))  # Redirect to login page in a real app
    return render_template('register.html', form=form)



# Rate limiter
#limiter = Limiter(get_remote_address, app=app)

# Environment-based credentials (in a real app, these would come from a database)
#USERNAME = os.getenv('LOGIN_USERNAME', 'admin')
#HASHED_PASSWORD = bcrypt.hashpw(os.getenv('LOGIN_PASSWORD', 'password123').encode('utf-8'), bcrypt.gensalt())
USERNAME = "admin"
PASSWORD = "password123"

@app.route('/')
def home():
    return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
#@limiter.limit("5 per minute")  # Limit login attempts
def login():
    PAGE_VIEWS.labels(endpoint="home").inc()
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']

        #if username == USERNAME and password == PASSWORD:
        user = User.query.filter_by(username=username).first()

        if user and bcrypt.check_password_hash(user.password, password):
            session['username'] = username  # Store username in session
            flash('Login successful!', 'success')
            return redirect(url_for('dashboard'))
        else:
            flash('Invalid username or password', 'danger')

    return render_template('login.html')

@app.route('/dashboard')
def dashboard():
    PAGE_VIEWS.labels(endpoint="dashboard").inc()
    username = session.get('username', 'Guest')  # Get username from session
    return f"Welcome to the Dashboard, {username}!"  # Personalize the welcome message


@app.route('/users', methods=['GET'])
def list_users():
    # Query all users from the database
    users = User.query.all()

    # Pass the users list to the template
    return render_template('users.html', users=users)

@app.route('/metrics')
def metrics():
    # Increment the request counter for each request to the app
    REQUEST_COUNT.inc()
    return generate_latest()


if __name__ == '__main__':
    # Expose the Prometheus metrics as a WSGI app
    #app.wsgi_app = make_wsgi_app()
    app.run(debug=True,host='0.0.0.0', port=5000)
