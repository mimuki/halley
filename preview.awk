awk 'BEGIN {RS="--------------\n"} /status id: '$1'/ {print}' \
$HOME/.config/msync/msync_accounts/$2/notifications.list \
$HOME/.config/msync/msync_accounts/$2/home.list \
  | awk '!a[$0]++' \
  | awk '
    # Set text colour, using terminal colour codes
    function recolour(colour, text) { return sprintf("\033[38;5;%03dm%s\033[0m", colour, text) }
    # Bold text, can be stacked with recolour() 
    function bold(text) { return sprintf("\033[1m%s\033[0m", text) }

    # If the terminal doesnt support colour, dont try to show it
    BEGIN { if ("NO_COLOR" in ENVIRON || match (ENVIRON["TERM"], "^(dumb|network|9term)")) noColour = 1 }

    /^notification id: / { next }
    /^at ([0-9]+-)+/ { next }
    /^status id: / { next } 
    /^url: / { next }

    # post author
    /^author: / {
      sub(/^author: /, " "); 

      if (noColour) { print }
      else { print bold(recolour("6", $0)) }
      next                    
    }                         

    /^reply to: / { next }
    
    /^cw: / { 
      if (noColour) { print }
      else { print recolour("4", $0) }

      system("sleep " 5) ;
      next 
      }

    /^attached:.*$/ { next } 
    /^http.*$/ { next } 

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
      # Convert current date to users itmezone
      cmd = sprintf("date -d '%s'", UTCdate) 
      cmd | getline date
      close(cmd)
      next
    } 

    /^[0-9]+ favs \| / {
      # Custom date format stuff! 
      # Default format is Mon 18 Sep 2023 06:09:28 TIMEZONE
      weekday = substr(date,  0, 3)
      day     = substr(date,  5, 2)
      month   = substr(date,  8, 3)
      year    = substr(date, 12, 4)
      hour    = substr(date, 17, 2)
      minute  = substr(date, 20, 2)
      second  = substr(date, 23, 2)

      # Convert month to number
      if      ( month == "Jan" ) { month =  1 }
      else if ( month == "Feb" ) { month =  2 }
      else if ( month == "Mar" ) { month =  3 }
      else if ( month == "Apr" ) { month =  4 }
      else if ( month == "May" ) { month =  5 }
      else if ( month == "Jun" ) { month =  6 }
      else if ( month == "Jul" ) { month =  7 }
      else if ( month == "Aug" ) { month =  8 }
      else if ( month == "Sep" ) { month =  9 }
      else if ( month == "Oct" ) { month = 10 }
      else if ( month == "Nov" ) { month = 11 }
      else if ( month == "Dec" ) { month = 12 }

      # 12 hour conversion
      if ( hour == "00" ) { 
        meridiem = "AM"; 
        twelveHour = "12"
      } else if ( hour == 12 ) {
        meridiem = "PM"
        twelveHour = "12"
      } else if ( hour < 12 ) { 
        meridiem = "AM" 
        twelveHour = hour
      } else {
        meridiem = "PM"
        twelveHour = hour - 12
      }

      # Change this to customize the format
      date = sprintf("%02d", twelveHour) ":" sprintf("%02d", minute) " " meridiem " · " weekday " " sprintf("%02d", day) "/" sprintf("%02d", month) "/" year

      # Replace with this one for 24 hour
      # date = sprintf("%02d", hour) ":" sprintf("%02d", minute) " · " weekday " " sprintf("%02d", day) "/" sprintf("%02d", month) "/" year

      # Needed because we check two files that may differ- if a post is in both the home TL
      # and in a notification, the number of replies can vary causing both to get printed
      if (!printed) {
        sub(/^[0-9]+ favs \| [0-9]+ boosts \| /, ""); 
        print visibility, $(NF-1), "replies · " date; 
        printed=1
      }
      next; 
    }
  '
