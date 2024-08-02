export LEARN_COMMAND="sudo mysql"
export LEARN_SCHEMA_NAME="root"
export LEARN_TABLE_NAME="learnings_collection"
export LEARN_DEFAULT_CATEGORY="programming"

function learnSearch() {
  categoryScope=""

  while getopts 'c:' OPTION; do
    case "$OPTION" in
      c)
        categoryScope="WHERE category = '$OPTARG'"
        ;;
    esac
  done

  shift "$(($OPTIND -1))"

  if [[ -z "$1" ]]; then
    echo "Missing search argument" >&2
    return 1
  fi

  searchArg=$1
  echo "SELECT id, category, learning FROM $LEARN_SCHEMA_NAME.$LEARN_TABLE_NAME $categoryScope ORDER BY dateAdded;" | ${=LEARN_COMMAND} | sed 's/^\([0-9]*\)\s\+\([a-zA-Z]*\)\s\+\(.*\)$/\1-\2: \3/' | rg -i $searchArg
}

function learnAdd() {
  local learning

  category=$LEARN_DEFAULT_CATEGORY

  while getopts 'ec:' OPTION; do
    case "$OPTION" in
      e)
        filename="/tmp/edit-note"
        touch $filename
        $EDITOR $filename
        learning=$(cat $filename)
        rm $filename
        ;;
      c)
        category=$OPTARG
        ;;
    esac
  done

  shift "$(($OPTIND -1))"

  if [[ -z $learning ]]; then
    learning=$1
  fi

  if [[ -z $learning ]]; then
    echo "Missing learn argument" >&2
    return 1
  fi

  echo "INSERT INTO $LEARN_SCHEMA_NAME.$LEARN_TABLE_NAME (category, learning, dateAdded) VALUES ('"$category"', '""$learning""', now());" | ${=LEARN_COMMAND}
}

function learnDelete() {
  if [[ -z $1 ]]; then
    echo "Missing id" >&2
    return 1
  fi

  echo "DELETE FROM $LEARN_SCHEMA_NAME.$LEARN_TABLE_NAME WHERE id = "$1";" | ${=LEARN_COMMAND}
}

function learnEdit() {
  if [[ -z $1 ]]; then
    echo "Missing id" >&2
    return 1
  fi

  content=$(echo "SELECT learning FROM $LEARN_SCHEMA_NAME.$LEARN_TABLE_NAME WHERE id = $1;" | sudo mysql --silent)

  filename="/tmp/edit-note"
  touch $filename
  echo $content >> $filename
  $EDITOR $filename
  learning=$(cat $filename)
  rm $filename

  if [[ -z $learning ]]; then
    echo "Content cannot be empty" >&2
    return 1
  fi

  echo "UPDATE $LEARN_SCHEMA_NAME.$LEARN_TABLE_NAME SET learning='"$learning"' WHERE id = $1;" | ${=LEARN_COMMAND}
}

function learnDbCreate() {
  echo "CREATE SCHEMA IF NOT EXISTS $LEARN_SCHEMA_NAME;" | ${=LEARN_COMMAND}
  echo 'CREATE TABLE `'"$LEARN_TABLE_NAME"'` ( `category` VARCHAR(20) DEFAULT NULL, `learning` VARCHAR(3000) DEFAULT NULL, `dateAdded` DATETIME DEFAULT NULL, `id` int(11) NOT NULL AUTO_INCREMENT, PRIMARY KEY (`id`));' | ${=LEARN_COMMAND} -D "$LEARN_SCHEMA_NAME"
}

function learnDbDrop() {
  echo "USE $LEARN_SCHEMA_NAME; DROP TABLE $LEARN_TABLE_NAME;" | ${=LEARN_COMMAND}
}
