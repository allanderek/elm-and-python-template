# Development

To create the virtual environment run:
$ python3 -m venv venv
$ source venv/bin/activate.fish 
$ pip install -r requirements.txt

If already created you only need the middle line:
$ source venv/bin/activate.fish 


## TODOS:

- [ ] Am I vulnerable to SQL-injection? I don't believe so because we're using SQL params and not string interpolation.
