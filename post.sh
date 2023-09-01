ACCOUNT=$1
REPLYID=$2

# -n = if the length of the string is non-zero (you pressed the reply binding)
if [ -n "$REPLYID" ]
then
  # awk to check if the status has a CW
  # then cut off the "cw: " part if it does
  CW="$(awk "/^status id: $REPLYID/ {f=1} f && /^-----/ {exit} f && /cw:/ {print; exit}" $HOME/.config/msync/msync_accounts/$ACCOUNT/home.list | cut -c 5-)"

  # TODO: this but good
  if [ -n "$CW" ]
  then
    msync generate --reply-to $REPLYID --content-warning "$CW"
  else
    msync generate --reply-to $REPLYID
  fi
else
  msync generate 
fi
# Jump to end of file, ready to write a post
# caveat: you need to q! even if you haven't done anything else,
# since by adding a new line it modifies the file
vim -c 'execute "normal GGo"'  new_post

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
