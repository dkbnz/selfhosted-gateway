.PHONY: docker link setup gateway

build:
	docker --host ssh://$(GATEWAY) build -t dkbnz/shgw:latest ./src/gateway/
	docker --host ssh://$(GATEWAY) build -t dkbnz/shgw-link-host:latest ./src/link-host/
	docker build -t dkbnz/shgw-link-client:latest ./src/link-client/
	docker build -t dkbnz/shgw-link-init:latest ./src/link-init/

gateway:
	docker --host ssh://$(GATEWAY) network create gateway
	docker --host ssh://$(GATEWAY) run \
		--network gateway \
		--restart unless-stopped \
		-p 80:80 \
		-p 443:443 \
		-e NGINX_ENVSUBST_OUTPUT_DIR=/etc/nginx \
		-it -d dkbnz/shgw:latest

link:
	docker run -v /<your-home-directory>/.ssh:/root/.ssh --rm -it dkbnz/shgw-link-init:latest $(GATEWAY) $(FQDN) $(EXPOSE)
