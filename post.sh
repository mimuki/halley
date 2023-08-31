ACCOUNT=$1 

msync generate 
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
