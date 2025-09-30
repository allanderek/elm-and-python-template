# Development

To create the virtual environment run:
$ python3 -m venv venv
$ source venv/bin/activate.fish 
$ pip install -r requirements.txt

If already created you only need the middle line:
$ source venv/bin/activate.fish 


# To use the template to create a new project

copier copy gh:allanderek/elm-and-python-template new-project-name

# Fill in the .env file

Otherwise things won't work.


# Setup hooks

Once you have run `git init`, you should run `./setup_hooks.sh` to set up the pre-commit hooks, this prevents you from commiting your `.env` file into your repository by mistake. Once you have done this you can delete the `setup_hooks.sh` file and the `hooks` directory, they don't need to be in your new project's repository.
