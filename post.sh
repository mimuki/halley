ACCOUNT=$1
REPLYTO=$2
DIR=$HOME/.config/msync/msync_accounts/$ACCOUNT/

# Number of posts in the queue
# checks all user directories, is a bit scuffed as a result
# TODO: make this a bit less ugly
ID=$((1+$(ls -l ${DIR}../*/queuedposts/ | grep -v .bak | grep '\-rw\-rw\-r\-\-'| wc -l)))
TIME=$(date +%H:%M)
TITLE="${ID}_${TIME}"

# -n = if the length of the string is non-zero (you pressed the reply binding)
if [ -n "$REPLYTO" ]
then
  # awk to check if the status has a CW
  # then cut off the "cw: " part if it does
  CW="$(awk "/^status id: $REPLYTO/ {f=1} f && /^-----/ {exit} f && /cw:/ {print; exit}" $DIR/home.list | cut -c 5-)"
  # Get the @ of who you're replying to
  # This doesn't automatically mention other people
  # like people who the post mentions (that arent the poster)
  # ...arguably, this is a feature
  AUTHOR="$(awk "/^status id: $REPLYTO/ {f=1} f && /^-----/ {exit} f && match(\$0, /author: ([^\n]+) \((@[^\n]+)\)/, m) {print m[2]; exit }" $DIR/home.list)\<Space>"
  # TODO: this looks ugly, i should learn a better way
  if [ -n "$CW" ]
  then
    msync generate --reply-to $REPLYTO --reply-id $ID --output $TITLE --content-warning "$CW"
  else
    msync generate --reply-to $REPLYTO --reply-id $ID --output $TITLE
  fi
else
  msync generate --reply-id $ID --output $TITLE
fi


# Go to end of post, insert the mention on a new line, then go to the end of 
#   the line (after the space!) & enter insert mode.
#   caveat: you need to q! even if you haven't done anything else,
#   since by adding a new line it modifies the file

# We type mentions like this, because prefilling them with msync means quitting 
#   will still queue a post (because it technically has a body)
vim -c 'execute "normal GGo'$AUTHOR'"' -c 'startinsert' -c 'execute "normal $"' $TITLE

# -s = if the file exists and has a non-zero size
if [ -s "$TITLE" ]
then
  postout="$(msync queue post $TITLE --account $ACCOUNT)"
  # -z = if the length of the string is 0 (in this case: everything is ok)
  if [ -z "$postout" ]
  then
    echo "Post enqueued."
  else
    echo "$postout"
  fi
else
  echo "Post empty. Not enqueueing."
fi
rm $TITLE
