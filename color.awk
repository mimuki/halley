#!/usr/bin/awk -f

# Set text colour, using the terminal colour codes
function recolour(colour, text) { return sprintf("\033[38;5;%03dm%s\033[0m", colour, text) }
# Embolden text, can be stacked with recolour()
function bold(s) { return sprintf("\033[1m%s\033[0m", s) }

# See if the terminal reports it can't do colour,
# or it's a terminal we know can't
# If the terminal can't do colours, don't even try.
BEGIN { if ("NO_COLOR" in ENVIRON || match(ENVIRON["TERM"], "^(dumb|network|9term)")) no_color = 1 }
no_color { next }

# Post author
/^ / { print bold(recolour("6", $0)); next }

# Content warning
/^cw: / { print recolour("4", $0); next }

# Hashtag & username highlighting
{

  for (i = 1; i <= NF; i++) {
    s = gensub(/^(@[a-zA-Z0-9_\-.@]+)/, recolour("2", "\\1"), "g", $i)
    $i = s
  }

  for (i = 1; i <= NF; i++) {
    s = gensub(/(#[a-zA-Z0-9_\-]+)/, recolour("5", "\\1"), "g", $i)
    $i = s
  }

  print
}
