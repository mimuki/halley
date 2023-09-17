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
      UTCday    = substr($0, 9, 2)
      UTCmonth  = substr($0, 6, 2)
      UTCyear   = substr($0, 0, 4)
      UTChour   = substr($0, 12, 2)
      UTCminute = substr($0, 15, 2)

      # UTC offset as either - or + (ahead or behind)
      cmd = "date +%z | head -c 1"
      cmd | getline offsetDirection
      close(cmd)
      # Current hour (24h)
      cmd = "date +%z | head -c 3 | tail -c 2"
      cmd | getline offsetHour
      close(cmd)
      # Current minute
      cmd = "date +%z | head -c 5 | tail -c 2"
      cmd | getline offsetMinute
      close(cmd)
      next
    } 

    /^[0-9]+ favs \| / {
      # This giant wall handles adjusting msync timezone to your timezone
      if (offsetDirection == "+") { minute = UTCminute + offsetMinute }
      if (offsetDirection == "-") { minute = UTCminute - offsetMinute }
      # if your minute offset makes something an hour later...
      if ( minute > 59 ) { 
        minute = minute - 60
        hourAdjustment = 1
      } else { 
        # if your offset makes something an hour earlier
        # idk if this timezone even exists, but still.
        if ( minute < 0 ) {
          minute = minute + 60
          hourAdjustment = -1
        } else { hourAdjustment = 0 }
      }

      # add leading zeroes if needed:
      minute = sprintf("%02d", minute)

      if (offsetDirection == "+") { hour = UTChour + offsetHour + hourAdjustment }
      if (offsetDirection == "-") { hour = UTChour - offsetHour + hourAdjustment }

      # if your hour offset makes it a day later...
      if ( hour > 23) {
        hour = hour - 24
        dayAdjustment = 1
      } else { 
        # if your hour offset makes it a day earlier
        if (hour < 0) {
          hour = hour + 24
          dayAdjustment = -1
        # no change to day needed
        } else { 
          dayAdjustment = 0 
        }
      }

      # after hour adjustments, do AM/PM handling
      # comment this out (and remove later references to meridiem) for 24h
      if ( hour < 12 ) { 
        meridiem = "AM" 
      } else {
        meridiem = "PM"
        hour = hour - 12
      }
         
      day = UTCday + dayAdjustment

      # Different months have different lengths 
      if ( UTCmonth == 04 || UTCmonth == 06 || UTCmonth == 09 || UTCmonth == 11 ) {
        monthLength = 30
        # needed for underflow
        prevMonthLength = 31
      } 

      if ( UTCmonth == 01 || UTCmonth == 03 || UTCmonth == 05 || UTCmonth == 07 || UTCmonth == 08 || UTCmonth == 10 || UTCmonth == 12) { 
        monthLength == 31 
        # Underflow rules are less pretty here
        if ( UTCmonth == 01 || UTCmonth == 08) { prevMonthLength = 31 } 
        if ( UTCmonth == 03) {
          # the leap year rules are fucked up, actually
          if (UTCyear % 100 == 0) {
            if (UTCyear % 400 == 0) { 
              prevMonthLength == 29
            } else { prevMonthLength == 28 }
          } else { prevMonthLength == 29 }
        }
        if ( UTCmonth == 05 || UTCmonth == 07 || UTCmonth == 10 || UTCmonth == 12) {
          prevMonthLength == 30
        }
      } 
      # February in particular is a bastard
      if (UTCmonth == 02) {
        # the leap year rules are fucked up, actually
        if (UTCyear % 100 == 0) {
          if (UTCyear % 400 == 0) { 
            monthLength == 29
          } else { monthLength == 28 }
        } else { monthLength == 29 }
      }
      if ( day > monthLength ) {
        day = day - monthLength
        monthAdjustment = 1
      } else { 
        if ( day < 0 ) { 
          day = day + prevMonthLength
          monthAdjustment = -1
        } else { monthAdjustment = 0 }
      }

      month = UTCmonth + monthAdjustment
      if (month > 12) {
        month = month - 12
        yearAdjustment = 1
      } else { 
        if (month < 0) { 
          month = month + 12
          yearAdjustment = -1
        }
      } 
      year = UTCyear + yearAdjustment

      # Needed because we check two files that may differ- if a post is in both the home TL
      # and in a notification, the number of replies can vary causing both to get printed
      if (!printed) {
        sub(/^[0-9]+ favs \| [0-9]+ boosts \| /, ""); 
        print visibility, $(NF-1), "replies · " hour ":"  minute " " meridiem " · " day "/" month "/" year; 
        printed=1
      }
      next; 
    }
  '
