ACCOUNT=$1
REPLYTO=$2
DIR=$HOME/.config/msync/msync_accounts/$ACCOUNT/

# Number of posts in the queue
ID=$(ls -l ${DIR}queuedposts/ | grep -v .bak | grep -v ^d | wc -l)
TIME=$(date +%H:%M)
TITLE="${ID}_${TIME}"

# -n = if the length of the string is non-zero (you pressed the reply binding)
if [ -n "$REPLYTO" ]
then
  # awk to check if the status has a CW
  # then cut off the "cw: " part if it does
  CW="$(awk "/^status id: $REPLYTO/ {f=1} f && /^-----/ {exit} f && /cw:/ {print; exit}" $DIR/home.list | cut -c 5-)"

  # TODO: this but good
  if [ -n "$CW" ]
  then
    msync generate --reply-to $REPLYTO --reply-id $ID --output $TITLE --content-warning "$CW"
  else
    msync generate --reply-to $REPLYTO --reply-id $ID --output $TITLE
  fi
else
  msync generate --reply-id $ID --output $TITLE
fi

# Jump to end of file, ready to write a post
# caveat: you need to q! even if you haven't done anything else,
# since by adding a new line it modifies the file
vim -c 'execute "normal GGo"' $TITLE

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
