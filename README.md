# Development

To create the virtual environment run:
$ python3 -m venv venv
$ source venv/bin/activate.fish 
$ pip install -r requirements.txt

If already created you only need the middle line:
$ source venv/bin/activate.fish 


# To use the template to create a new project

copier copy gh:allanderek/elm-and-python-template new-project-name --trust

or you can copy locally, for example from the directory containing this repo:

copier copy elm-and-python-template new-project-name --trust

You need the `--trust` flag because we use "tasks" in the copier.yaml file. If you're unsure about this, clone repo locally, edit out the tasks section in copier.yaml and then you can run the copier command without the `--trust` flag. You will have to create a `.env` file yourself, but that's a minor inconvenience.

# Fill in the .env file

Otherwise things won't work.


# Setup hooks

Once you have run `git init`, you should run `./setup_hooks.sh` to set up the pre-commit hooks, this prevents you from commiting your `.env` file into your repository by mistake. Once you have done this you can delete the `setup_hooks.sh` file and the `hooks` directory, they don't need to be in your new project's repository.


