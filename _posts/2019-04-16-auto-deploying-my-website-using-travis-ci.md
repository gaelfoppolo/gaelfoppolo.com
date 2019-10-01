---
title: Auto deploying my website using Travis CI
categories: [continuous deployment]
---

Since I set up this blog, I wanted two things: owning my data and remove any unnecessary manual operation. Using Jekyll, I already achieved the former. Let's achieve the latter in 50 lines of code.

While figuring things out, I decided to document my solution, so that others could do the same, without the burden part. 

# Continuous Deployment

Continuous Deployment is the practice of deploying small changes frequently — rather than deploying a big change at the end of a development cycle. For example, GitHub deploys into production about 80 times a day.

The goal is to build healthier software by developing and testing in smaller increments. The same apply to content delivering.

## Say hi to Travis

[Travis CI](https://travis-ci.org) is a free Continuous Integration service for building, testing and deploying your GitHub projects. The service is free for open source repositories. 

Travis allows us to have reproducible and clean builds, notifications, conditionals and a lot more. This is exactly what I want.

# Workflow

Our workflow will be simple, a single job with several phases.

1. Configuring the job
2. Installing the dependencies
3. Building the site
4. Deploying

{% standard %}
The complete job lifecycle in Travis is [described here](https://docs.travis-ci.com/user/job-lifecycle#the-job-lifecycle).
{% endstandard %}

## Configure

To tell Travis CI what to do, we have to declare a `.travis.yml` file. Begin to fill it with the following content.

{% highlight yaml %}
os: osx
language: ruby
rvm: 2.6.0
sudo: false

notifications:
  email:
    recipients:
    - $EMAIL
    on_success: always
    on_failure: always

before_install:
  - gem update
{% endhighlight %}

This is quite self-explanatory. We want to use macOS, our project is Ruby based and we wish to have email notifications. That our environment.

The first phase also takes place, before installing our dependencies, we make our Gems up-to-date.

{% info %}
Notice the `$EMAIL` variable. With Travis we can declare environment variables, which can be used to hold information. The e-mail is a sensitive information, hence we use a "Repository Environment Variable". To define variables, make sure you’re logged in, navigate to the repository in Travis, choose “Settings” from the cog menu, and click on “Add new variable” in the [“Environment Variables” section](https://docs.travis-ci.com/user/environment-variables#defining-variables-in-repository-settings).
{% endinfo %}

## Install

Next up, we install the dependencies.

{% highlight yaml %}
install:
  - bundle install
{% endhighlight %}

## Build

In this phase, we build our website.

First, we declare a new type of environment variable. This one is located inside the `.travis.yml` file, because there is no sensitive information. `JEKYLL_ENV` is a [Jekyll variable](https://jekyllrb.com/docs/configuration/environments/), `JEKYLL_CONF` and `LOCAL_FOLDER` are ones of mine.

{% highlight yaml %}
env:
  global:
  - JEKYLL_ENV=production
  - LOCAL_FOLDER=_site
  - JEKYLL_CONF=_config.yml
{% endhighlight %}

Coming next, the generation of the blog.

{% highlight yaml %}
script:
  - bundle exec jekyll build --config $JEKYLL_CONF
  - bundle exec htmlproofer ./$LOCAL_FOLDER --check-favicon --check-html --http_status_ignore 999 --disable-external
  - mv $LOCAL_FOLDER $REMOTE_FOLDER
{% endhighlight %}

I don't have tests (yet), but I could have run them in the `before_script` phase, for example. If they'd fail, my job would  also fail. The build and deploy phases would not occur.
At the moment I use [HTMLProofer](https://github.com/gjtorikian/html-proofer) to check the HTML validity (links, etc.).
`$REMOTE_FOLDER` is an environment variable. 

## Deploy

We are at the core of the job. Our content is ready, we need to deliver it onto our web server.

Travis offers a plethora of deployment strategies, to numerous providers like AWS or Heroku. But I want to deploy to my own provider, using `rsync`through SSH. Fortunately, Travis provides features we can use to achieve that.

Using SSH implies having the private key available in the Travis build. But we don't want having this highly sensitive information in the GitHub repository. Well, not in that form. So first, we need to encrypt the private key to make it readable only by Travis.

### One-time configuration

The steps are:

1. Generate a new, dedicated SSH key
2. Copy the public key onto the remote SSH host (web server)
3. Encrypt the private key and add it to Travis
4. Commit the encrypted key in the repository

{% highlight shell %}
ssh-keygen -t rsa -b 4096 -C 'build@travis-ci.org' -f ./deploy_rsa
# enter an empty passphrase

ssh-copy-id -i deploy_rsa.pub <user>@<host>
# check the public key is in ~/.ssh/authorized_keys

gem install travis 
# login into Travis
travis login --org --auto
# encrypt the private key 
travis encrypt-file deploy_rsa --add

git commit -m "Add encrypted SSH private key" deploy_rsa.enc
{% endhighlight %}

The Travis CLI utility created an encrypted version of the private key and store the decryption key as an environment variable on Travis. It also added some lines to the `.yml` file which will decrypt the private key file during the build.

### Job configuration

`rsync` is a powerful utility for efficiently transferring files between two computers. On macOS, the utility is available through HomeBrew. The package will be installed before our workflow kicks in, at environment configuration. Don't forget to add these two new environment variables as well.

{% highlight yaml %}
addons:
  homebrew:
    packages:
    - rsync

env:
  global:
  - DEPLOY_KEY=deploy_rsa
{% endhighlight %}

The last step of our configuration will be composed of three phases:

- Before deployment, where we prepare the SSH configuration: we ensure the private key is decrypted and added to the build host.
- Deployment, this is where `rsync` does its part, uploading the blog into our web server, securely. I choose to only deploy the `master` branch.
- After deployment, we do some house cleaning, for safety purpose, even if Travis's builds are destroyed afterwards.

{% highlight yaml %}
before_deploy:
- ssh-keyscan -t rsa -H $HOST >> $HOME/.ssh/known_hosts
- openssl aes-256-cbc -K $encrypted_XXXXXXXX_key -iv $encrypted_XXXXXXXX5_iv -in $DEPLOY_KEY.enc -out /tmp/$DEPLOY_KEY -d
- eval "$(ssh-agent -s)"
- chmod 600 /tmp/$DEPLOY_KEY
- ssh-add /tmp/$DEPLOY_KEY

deploy:
  provider: script
  skip_cleanup: true
  script: rsync --recursive --relative --delete-after --progress --stats $REMOTE_FOLDER $USERNAME@$HOST:$REMOTE_PATH
  on:
    branch: master

after_deploy:
- ssh-add -D /tmp/$DEPLOY_KEY
- rm /tmp/$DEPLOY_KEY
{% endhighlight %}

Same as before, notice the new environment variables. Add the three of them as "Repository Environment Variable", with the proper values: `$HOST`, `$USERNAME` and `$REMOTE_PATH`.  

# Wrapping up

{% highlight yaml %}
os: osx
language: ruby
rvm: 2.6.0
sudo: false

notifications:
  email:
    recipients:
    - $EMAIL
    on_success: always
    on_failure: always

env:
  global:
  - JEKYLL_ENV=production
  - DEPLOY_KEY=deploy_rsa
  - LOCAL_FOLDER=_site
  - JEKYLL_CONF=_config.yml

addons:
  homebrew:
    packages:
    - rsync

before_install:
  - gem update

install:
  - bundle install

script:
  - bundle exec jekyll build --config $JEKYLL_CONF
  - bundle exec htmlproofer ./$LOCAL_FOLDER --check-favicon --check-html --http_status_ignore 999 --disable-external
  - mv $LOCAL_FOLDER $REMOTE_FOLDER

before_deploy:
- ssh-keyscan -t rsa -H $HOST >> $HOME/.ssh/known_hosts
- openssl aes-256-cbc -K $encrypted_XXXXXXXX_key -iv $encrypted_XXXXXXXX5_iv -in $DEPLOY_KEY.enc -out /tmp/$DEPLOY_KEY -d
- eval "$(ssh-agent -s)"
- chmod 600 /tmp/$DEPLOY_KEY
- ssh-add /tmp/$DEPLOY_KEY

deploy:
  provider: script
  skip_cleanup: true
  script: rsync --recursive --relative --delete-after --progress --stats $REMOTE_FOLDER $USERNAME@$HOST:$REMOTE_PATH
  on:
    branch: master

after_deploy:
- ssh-add -D /tmp/$DEPLOY_KEY
- rm /tmp/$DEPLOY_KEY
{% endhighlight %}

or [here](https://github.com/gaelfoppolo/gaelfoppolo.com/blob/master/.travis.yml) for an up-to-date version.

You can now deploy automatically by pushing new content on the master branch, multiple times a day, and, avoiding any misfortune from using your own machine.

Isn't that marvelous?