awk 'BEGIN {RS="--------------\n"} /status id: '$1'/ {print}' \
$HOME/.config/msync/msync_accounts/$2/notifications.list \
$HOME/.config/msync/msync_accounts/$2/home.list \
  | awk '!a[$0]++' \
  | awk '
    # Set text colour, using terminal colour codes
    function colour(format, colourCode, text) {
      if (format == "fg") { return sprintf("\033[38;5;%03dm%s\033[0m", colourCode, text) }
      if (format == "bg") { return sprintf("\033[48;5;%03dm%s\033[0m", colourCode, text) }
    }
    # Set text effects like bold and underline 
    function style(format, text) {
      if (format == "bold"  ) { return sprintf("\033[1m%s\033[0m", text) }
      if (format == "line"  ) { return sprintf("\033[4m%s\033[0m", text) }
      if (format == "strike") { return sprintf("\033[9m%s\033[0m", text) }
      if (format == "blink" ) { return sprintf("\033[5m%s\033[0m", text) }
    }

    # If the terminal doesnt support colour, dont try to show it
    BEGIN { 
      if ("NO_COLOR" in ENVIRON || match (ENVIRON["TERM"], "^(dumb|network|9term)")) {
        noColour = 1
      }
    }
    /^notification id: / { next }
    /^at ([0-9]+-)+/ { next }
    /^status id: / { next } 
    /^url: / { next }
    # post author
    /^author: / {
      sub(/^author: /, "🐘"); 
      if (noColour) { print }
      else { print colour("fg", "6", style("bold", $0)) }
      next                    
    }                         
    /^reply to: / { next }
    /^cw: / { 
      if (noColour) { print }
      else { print colour("fg", "4", $0) }

      system("sleep " 5) ;
      next 
      }

    /^attached:.*$/ { next } 
    /^http.*$/ { print colour("fg", "6", $0); next }

    # works but prints the entire rest of the post,  need to mess with this another time
    # #/`/{                                                   
    #  s=$0
    #  while (match(s, /([^`]*)`([^`]+)`/, arr)){
    #    printf "%s%s", arr[1], bgColour("0", arr[2])
    #    s=substr(s, RLENGTH+1) 
    #  }
    #  print s
    #  next
    #}1

    (!noColour) {
      # Highlight mentions
      for (i = 1; i <= NF; i++) {
        s = gensub(/^(@[a-zA-Z0-9_\-.@]+)/, colour("fg", "2", "\\1"), "g", $i)
        $i = s
      }
      # Highlight hashtags
      for (i = 1; i <= NF; i++) {
        s = gensub(/(#[a-zA-Z0-9_\-]+)/, colour("fg", "5", "\\1"), "g", $i)
        $i = s
      }
    }

    # post every line in the body
    # (with a newline at the top for spacing)
    # TODO: theres a bug where blank lines are inconsistently printed
    /^body: / { 
      sub(/body: /, "");
      print "";
      post=1
    }

    /^description: / { 
      print "" # Add a newline for spacing
      post=0;
      altText=1
    }

    /^poll id: / { print ""; next }

    /^expires at: / {
      sub(/^expires at: /, "")
      expiry = $0
      pollFormat = "%I:%M\\ %P\\ on\\ %A\\ %d/%m/%Y"
      cmd = sprintf("date -d '%s' +%s", expiry, pollFormat) 
      cmd | getline expiry
      close(cmd)
      pollInfo = sprintf("\n(poll ends at %s)", expiry)
      next
    }
    /^visibility: / {
      post=0;
      altText=0
    }
    
    post
    altText

    # Save the visibility info for later
    /^visibility: public/   { visibility = "\n📡"; next }                          
    /^visibility: unlisted/ { visibility = "\n📖"; next }                          
    /^visibility: private/  { visibility = "\n🔒"; next }        
    /^visibility: direct/   { visibility = "\n🎁"; next }        

    # Timestamps
    /^posted on: / { 
      sub(/^posted on: /, "")
      UTCdate = $0
      # see man date for info on how to customize this
      dateFormat = "%I:%M\\ %P\\ ·\\ %A\\ %d/%m/%Y"
      # Example: 24 hour time
      # dateFormat = "%H:%M\\ ·\\ %A\\ %d/%m/%Y"
      # Convert post date to users itmezone
      cmd = sprintf("date -d '%s' +%s", UTCdate, dateFormat) 
      cmd | getline date
      close(cmd)
      next
    } 

    /^[0-9]+ favs \| / {
      # Needed because we check two files that may differ- if a post is in both the home TL
      # and in a notification, the number of replies can vary causing both to get printed
      if (!printed) {
        sub(/^[0-9]+ favs \| [0-9]+ boosts \| /, ""); 
        print pollInfo, visibility, $(NF-1), "replies · " date; 
        printed=1
      }
      next; 
    }
  '
