less $DIR/$1 | \
awk '
BEGIN { if ("NO_COLOR" in ENVIRON || match (ENVIRON["TERM"], "^(dumb|network|9term)")) noColour = 1 }
  # Set text colour, using terminal colour codes                                           
  function recolour(colour, text) { return sprintf("\033[38;5;%03dm%s\033[0m", colour, text) }
  # Bold text, can be stacked with recolour() 
  function bold(text) { return sprintf("\033[1m%s\033[0m", text) }

  /^status id/ { next }
  /^reply_to/  { 
    if (noColour) { print }
    else { 
      sub(/^reply_to=/, "reply to: ")
      print recolour("6", $0) 
    }
    { next }
  }
  /^reply_id/  { next }

  /^cw/ {
    sub(/cw=/, "cw: ")
    if (noColour) { print }
    else { print recolour("4", $0) }
    system("sleep " 5) ;
    next
  }

  # Save the visibility info for later
  /^visibility=default/  { visibility = "\n(default visibility)"; next }
  /^visibility=public/   { visibility = "\n📡"; next }
  /^visibility=unlisted/ { visibility = "\n📖"; next }
  /^visibility=private/  { visibility = "\n🔒"; next }
  /^visibility=direct/   { visibility = "\n🎁"; next }

  /^--- post body below this line ---/ { next }

  (!noColour) {
    # Highlight mentions                                                                   
    for (i = 1; i <= NF; i++) {
      s = gensub(/^(@[a-zA-Z0-9_\-.@]+)/, recolour("2", "\\1"), "g", $i)
      $i = s
    }
    # Highlight hashtags
    for (i = 1; i <= NF; i++) {
      s = gensub(/(#[a-zA-Z0-9_\-]+)/, recolour("5", "\\1"), "g", $i)
      $i = s
    }
  }

  { print }
  END { print visibility }
'
