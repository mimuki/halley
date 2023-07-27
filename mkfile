TARG=open

all:V: $TARG

%: %.cr
	crystal build $stem.cr


