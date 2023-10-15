ACCOUNT=$1
MODE=$2
gawk -v mode="$MODE" '\
BEGIN {RS="--------------"}

/^\s*$/ { next }
# Skip boosts (TODO: make this optional and handle boosts properly)
/boosted by: ([^\n]+)/ {next}

{ idx = 0 }

match($0, /status id: ([^\n]+)/, m) { post[idx++] = m[1] }
match($0, /cw: ([^\n]+)/, m) { 
  if (mode == "home" ) { post[idx++] = sprintf("cw: %s · ", m[1]) }
}
# To show username instead of nick, change m[1] to m[2]
match($0, /author: ([^\n]+) \((@[^\n]+)\)/, m) { 
  if (mode == "home") { post[ idx++] = m[1] }
}

match($0, /(([0-9]+-?)+)T([0-9]+:[0-9]+):[0-9]+.[0-9]+Z, ([^\n]+)/, m) {
  if (mode == "notifications") { 
    for (i in m) {
      if      (m[i] ~ "favorited") { icon = "* " }
      else if (m[i] ~ "boosted"  ) { icon = "& " }
      else if (m[i] ~ "mentioned") { icon = "@ " }
      else if (m[i] ~ "poll"     ) { icon = "/ " }
      else if (m[i] ~ "followed" ) { icon = "f " }
      else if (m[i] ~ "?"        ) { icon = "? " }
      else    { icon = "x " }
      # split at @ to get the username
      split(m[4], u, "@")
      # sometimes theres a trailing bracket and i dont know why. but this fixes it
      split(u[2], u, "\\)")
      username=u[1]
    }
    post[idx++] = sprintf(icon username)
  }
}

{
  for (i in post) { printf(post[i] " ") }
  print ""
  delete post
  next
}
' $HOME/.config/msync/msync_accounts/$ACCOUNT/$MODE.list \
| gawk '{
  printf $1 " [" NR "] "; \
  for (i = 2; i <= NF; i++) {printf $i " " }
  printf "\n" 
}' \
| tac
