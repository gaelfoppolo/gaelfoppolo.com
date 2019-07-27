# gaelfoppolo.com [![Build Status](https://travis-ci.org/gaelfoppolo/gaelfoppolo.com.svg?branch=master)](https://travis-ci.org/gaelfoppolo/gaelfoppolo.com) 

This is my personal site and blog. It mostly contains content about Swift and iOS. However, I also write about other programming topics.

## Requirements

- Ruby 2.5.0+
- [Bundler](https://bundler.io) 2.0.1+

## Dependencies

- [jekyll](https://jekyllrb.com)
- jekyll-assets
- jekyll-time-to-read
- jekyll-archives
- jekyll-paginate-v2
- jekyll-feed
- rouge
- jekyll-compose

## Local usage

Clone the repository:

```
$ git clone https://github.com/gaelfoppolo/gaelfoppolo.com.git
$ cd gaelfoppolo.com/
```

Download the project dependencies with Bundler using the command:

```terminal
$ bundle install
```

### Building the site

```terminal
$ bundle exec jekyll build --config _config.yml
```

### Previewing the site locally

```terminal
$ bundle exec jekyll serve --watch --drafts --livereload  --incremental --open-url
```

This will open your browser to [localhost:4000](localhost:4000).

### Content writing

See [jekyll-compose](https://github.com/jekyll/jekyll-compose).

## Deploying

The site is configured with continuous deployment such that any push to the `master` branch on this repository automatically triggers a build and deploys the site, if successful. This is done using [Travis CI](https://travis-ci.org/).

Users with push access can deploy the site by running the following command:

```
$ git push origin master
```

You can monitor the status of a deploy in real-time [on this dashboard](https://travis-ci.org/gaelfoppolo/gaelfoppolo.com).

## License

All code is published under the [MIT License](https://opensource.org/licenses/MIT).