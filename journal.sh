#!/bin/bash
set -e

# Configuration
BUNDLER_CMD="bundle exec"
JEKYLL_CMD="jekyll"
BUNDLER_JEKYLL_CMD="$BUNDLER_CMD $JEKYLL_CMD"
JEKYLL_CONFIG=" --config _config.yml"

# Helper
function includeDrafts {
  DRAFT_SHORT="-d"
  DRAFT_LONG="--draft"
  if [[ "$1" == $DRAFT_SHORT || "$1" == $DRAFT_LONG ]]; then
    return 0
  else
    return 1
  fi
}

# Build
function fnBuild {
  echo "Running Jekyll build..."
  BUILD_ACTION="build"
  BUILD_CMD="$BUNDLER_JEKYLL_CMD build $JEKYLL_CONFIG"
  
  if includeDrafts $1; then
    echo "Including drafts..."
    BUILD_CMD+=" --drafts"
  fi
  
  $BUILD_CMD
}

# Clean
function fnClean {
  echo "Running Jekyll clean.."
  CLEAN_ACTION="clean"
  CLEAN_CMD="$BUNDLER_JEKYLL_CMD $CLEAN_ACTION $JEKYLL_CONFIG"
  
  rm -rf .jekyll-cache
  
  $CLEAN_CMD
}

# Server
function fnServe {
  echo "Running Jekyll server..."
  SERVE_ACTION="serve"
  SERVE_OPTIONS="--watch --livereload --incremental --open-url"
  SERVE_CMD="$BUNDLER_JEKYLL_CMD $SERVE_ACTION $SERVE_OPTIONS"

  if includeDrafts $1; then
    echo "Including drafts..."
    SERVE_CMD+=" --drafts"
  fi

  $SERVE_CMD

}

# Server
function fnPublish {
	echo "Publishing site to remote server..."
	# call lftp using settings
	echo $USERNAME;
	echo $PASSWORD;
	echo $HOST;
	if [[ "$USERNAME" == "" || "$PASSWORD" == "" || "$HOST" == "" ]]; then
		echo "  Error: Unable to determine settings to publish to remote server!"
		echo ""
		exit 1
	else
    	LOCALPATH='./_site'
		REMOTEPATH='/www'

		lftp -f "
		set ssl:verify-certificate no
		set sftp:auto-confirm yes
		open sftp://$HOST
		user $USERNAME $PASSWORD
		mirror --continue --reverse --delete --verbose $LOCALPATH $REMOTEPATH
		bye
		" 
	fi
}

# Help Info
function fnHelpInfo {
  echo "Usage: journal.sh [OPTIONS]..."
  echo "A command line blog management tool"
  echo ""
  echo "Options:"
  echo ""
  echo "  -b, --build    runs a jekyll build"
  echo "  -c, --clean    cleans out the site output directory"
  echo "  -h, --help     displays help info for the script"
  echo "  -m, --move     moves a draft to post or post to draft status"
  echo "  -n, --new      creates a new post or draft"
  echo "  -p, --publish  copies site via lftp to remote server"
  echo "  -s, --serve    runs the jekyll server"
  echo ""
  echo "Modifiers:"
  echo ""
  echo "  --build:"
  echo "    -d, --draft  includes drafts in jekyll build"
  echo "  --new:"
  echo "    -d, --draft  creates a new draft post"
  echo "  --move:"
  echo "    -d, --draft  moves a draft to post"
  echo "    -p, --post   moves a post to draft"
  echo "  --serve:"
  echo "    -d, --draft  includes draft in jekyll server"
  echo ""
  echo "Examples:"
  echo ""
  echo "  journal.sh --new \"Blog title\""
  echo "    Creates a new post with the given title"
  echo ""
  echo "  journal.sh --new \"Blog title\" \"1/1/2019\""
  echo "    Create a new post on a specific date"
  echo ""
  echo "  journal.sh --new --draft \"Blog title\""
  echo "    Creates a new draft post with the given title"
  echo ""
  echo "  journal.sh --build"
  echo "    Builds the site"
  echo ""
  echo "  journal.sh --publish"
  echo "    Runs rcp/rsync to copy built site to a remote server"
  echo ""
  echo "  journal.sh --list \"*2019*\""
  echo "    Lists all posts that have '2019' in the file name"
  echo ""
  echo "  journal.sh --move --draft \"2019-01-01-blog-title.md\""
  echo "    Moves the matching file from draft to post folder"
  echo ""
}

# Process command line# Parse options
case "$1" in
  -b)
    fnBuild "$2"
    ;;
  --build)
    fnBuild "$2"
    ;;
  -c)
    fnClean
    ;;
  --clean)
    fnClean
    ;;
  --clear)
    fnClean
    ;;
  -m)
    fnMove "$2" "$3"
    ;;
  --move)
    fnMove "$2" "$3"
    ;;
  -n)
    fnNew "$2" "$3" "$4"
    ;;
  --new)
    fnNew "$2" "$3" "$4"
    ;;
  -p)
    fnPublish
    ;;
  --publish)
    fnPublish
    ;;
  -s)
    fnServe "$2"
    ;;
  --serve)
    fnServe "$2"
    ;;
  *)
    fnHelpInfo
    ;;
esac
exit 0