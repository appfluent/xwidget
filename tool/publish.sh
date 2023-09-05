#!/bin/zsh

GIT_TAG=
GIT_REPO=https://github.com/appfluent/xwidget.git
WORK_DIR=~/xwidget_work
SRC_DIR=$WORK_DIR/src
OUT_FILE=$WORK_DIR/.publish
DRY_RUN_FLAG=
FORMAT_FLAG=
USAGE="Usage: $0 [options]  <version>
  -h, --help       Print this usage information.
  -f, --format     Format the source code.
  -d, --dry-run    Validate but do not publish the package."

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo $USAGE
      exit 0
      ;;
    -f|--format)
      FORMAT_FLAG=true
      shift 1
      ;;
    -d|--dry-run)
      DRY_RUN_FLAG=--dry-run
      shift 1
      ;;
    *)
      echo "Invalid option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$GIT_TAG" ]]; then
  echo '\e[31mERROR: Version tag required.\e[0m\n'
  echo $USAGE
  exit 1
fi

clone_repo() {
  rm -rf $WORK_DIR
  mkdir $WORK_DIR
  git clone --depth 1 --branch $GIT_TAG $GIT_REPO $SRC_DIR > $OUT_FILE 2>&1
  if [[ $? != 0 ]]; then
    cat $OUT_FILE
    exit 2
  fi
  echo "Successfully cloned branch '$GIT_TAG' to '$SRC_DIR'."
}

format_code() {
  cd_src_dir
  dart format bin lib > $OUT_FILE 2>&1
  if [[ $? != 0 ]]; then
    cat $OUT_FILE
    exit 3
  fi
  echo "Successfully formatted source code."
}

analyze_code() {
  cd_src_dir
  flutter analyze > $OUT_FILE 2>&1
  if [[ $? != 0 ]]; then
    cat $OUT_FILE
    exit 4
  fi
  echo "Successfully analyzed source code."
}

publish() {
  cd_src_dir
  dart pub publish $DRY_RUN_FLAG
  if [[ $? != 0 ]]; then
    exit 5
  fi
}

cd_src_dir() {
  cd $SRC_DIR > $OUT_FILE 2>&1
  if [[ $? != 0 ]]; then
    cat $OUT_FILE
    exit 100
  fi
}

clone_repo
if [[ $FORMAT_FLAG == true ]]; then
  format_code
fi
analyze_code
publish
echo "Done!"
