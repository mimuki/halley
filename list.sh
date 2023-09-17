# TODO: find a way of doing "if mode = whatever, only save x matches"
# for like, using the same script for listing notifications, home feed, etc
# a problem i ran into was adding the notification script's titles, and
# i think it has something to do with escaping the literal brackets and things
MODE=$2
awk --assign mode="$MODE" '
BEGIN {RS="--------------"}

/^\s*$/ {next}
# Skip boosts (TODO: make this optional and handle boosts properly)
/boosted by: ([^\n]+)/ {next}

{ idx = 0 }

match($0, /status id: ([^\n]+)/, m) { post[idx++] = m[1] }
match($0, /cw: ([^\n]+)/, m) { post[idx++] = sprintf("cw: %s · ", m[1]) }
# To show username instead of nick, change m[1] to m[2]
match($0, /author: ([^\n]+) \((@[^\n]+)\)/, m) { post[ idx++] = m[1] }

{
  for (i in post) { printf(post[i] " ") }
  print ""
  delete post
  next
}
' $HOME/.config/msync/msync_accounts/$1/home.list \
| awk '{
  printf $1 " [" NR "] "; \
  for (i = 2; i <= NF; i++) {printf $i " " }
  printf "\n" 
}' \
| tac
