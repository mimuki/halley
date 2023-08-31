ACCOUNT=$1
REPLYID=$2

# -n = if the length of the string is non-zero (you pressed the reply binding)
if [ -n "$REPLYID" ]
  then
    msync generate --reply-to $REPLYID
  else
    msync generate 
fi
vim "new_post"

# -s = if the file exists and has a non-zero size
if [ -s "new_post" ]
then
  postout="$(msync queue post "new_post" --account $ACCOUNT)"
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
rm "new_post"
