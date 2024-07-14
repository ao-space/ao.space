build:
	python3 ./build.py

run:
	docker network create ao-space
	HOME="/Users/User-Name-Here"
	DATADIR="$HOME/aospace"
	docker run -d --name aospace-all-in-one  \
        	--restart always  \
        	--network=ao-space  \
        	--publish 5678:5678  \
       		--publish 127.0.0.1:5680:5680  \
       		-v $DATADIR:/aospace  \
       		-v /var/run/docker.sock.raw:/var/run/docker.sock:ro  \
       		-e AOSPACE_DATADIR=$DATADIR  \
       		local/space-agent:v1.0.0