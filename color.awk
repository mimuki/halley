#!/usr/bin/awk -f
# colorize toots
# inspired by mblaze
#
# I'm gonna be real with you.
# I have no idea what the fuck is going on in here.
# I've just been hacking onto this,
# and saying the magic words that makes stuff happen.

function co(n, c) { e = ENVIRON["MCOLOR_" n]; return e ? e : c }
function fg(c, s) { return sprintf("\033[38;5;%03dm%s\033[0m", c, s) }
function so(s) { return sprintf("\033[1m%s\033[0m", s) }
function header() { hdr = 1; body = 0; ftr = 0 }
function bodyy() { hdr = 0; body = 1; ftr = 0 }
function footer() { hdr = 0; body = 0; ftr = 1 }
BEGIN { header(); if ("NO_COLOR" in ENVIRON || match(ENVIRON["TERM"], "^(dumb|network|9term)")) no_color = 1 }
no_color { print; next }
/^body: / {sub(/body: /, ""); print ""; bodyy()}
/^description: / { 
  print ""
  print $0; 
  next 
}

/\r$/ { sub(/\r$/, "") }
/^--------------$/ { nextmail = 1; print(fg(co("FF",232), $0)); next }
/^attached/ { if (body) print ""; footer() }


/^--- .* ---/ { print fg(co("SEP",242), $0); ftr = 0; sig = 0; next }
/^-----BEGIN .* SIGNATURE-----/ { sig = 1 }

-hdr && /^ / { print so(fg(co("FROM",6), $0)); next }
-hdr && /^↻ / { print so(fg(co("FROM",5), $0)); next }

nextmail { header(); nextmail = 0 }
hdr && /^·/ { print so(fg(co("FROM",14), $0)); next }
hdr { print fg(co("HEADER",12), $0); next }
ftr { print fg(co("FOOTER",244), $0); next }
/^-----BEGIN .* MESSAGE-----/ ||
/^-----END .* SIGNATURE-----/ { print fg(co("SIG",244), $0); sig = 0; next }
sig { print fg(co("SIG",244), $0); next }
/^> *> *>/ { print fg(co("QQQUOTE",152), $0); next }
/^> *>/ { print fg(co("QQUOTE",149), $0); next }
/^>/ { print fg(co("QUOTE",151), $0); next }

{
	nextmail = 0
	for (i = 1; i <= NF; i++) {
		s = gensub(/^(@[a-zA-Z0-9_\-.@]+)/, fg(co("ACTOR", 222), "\\1"), "g", $i)
		$i = s
	}

	for (i = 1; i <= NF; i++) {
		s = gensub(/(#[a-zA-Z0-9_\-]+)/, fg(co("ACTOR", 5), "\\1"), "g", $i)
		$i = s
              }

	print
}
