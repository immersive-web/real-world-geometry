LOCAL_BIKESHED := $(shell command -v bikeshed 2> /dev/null)

.PHONY: dirs

all: dirs out/plane-detection.html out/webxrmeshing-1.html

dirs: out

out:
	mkdir -p out

out/plane-detection.html: plane-detection.bs
ifndef LOCAL_BIKESHED
	curl https://api.csswg.org/bikeshed/ -F file=@plane-detection.bs -F output=err
	curl https://api.csswg.org/bikeshed/ -F file=@plane-detection.bs -F force=1 > out/plane-detection.html | tee
else
	bikeshed spec plane-detection.bs out/plane-detection.html
endif

out/webxrmeshing-1.html: webxrmeshing-1.bs
ifndef LOCAL_BIKESHED
	curl https://api.csswg.org/bikeshed/ -F file=@webxrmeshing-1.bs -F output=err
	curl https://api.csswg.org/bikeshed/ -F file=@webxrmeshing-1.bs -F force=1 > out/webxrmeshing-1.html | tee
else
	bikeshed spec webxrmeshing-1.bs out/webxrmeshing-1.html
endif