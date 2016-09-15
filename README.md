# appboy-stub-api
A simple fake Appboy backend for testing and mocking

# Building Locally
* Clone this repository.
* ```bundle install```
* Run the server by navigating to the root directory and running ```bundle exec rackup -p 4569``` from the command line.
* You can now make API POSTs to localhost:4569/v3/data

## Special API keys
There are various API keys that have special behavior in the stub api:
* `modal` - returns a modal IAM
* `full` - returns a full IAM
* `array` - returns several IAMs
* `sleep_x` - sleeps for x seconds before returning to simulate network or backend slowness

## Hosting on Heroku
If you want to host an instance of this stub API, http://herokuapp.com makes that very easy:

* Create a new heroku app through http://herokuapp.com
* Download and install the Heroku Toolbelt
* `heroku git:remote -a your-app-name` (replacing `your-app-name` with whatever name you used when creating your heroku app)
* `git push heroku master`

Once you have heroku set up, you can update it simply with `git push heroku master`
