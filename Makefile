.PHONY: docker link setup gateway

build:
	docker --host ssh://$(GATEWAY) build -t dkbnz/gateway:latest ./src/gateway/
	docker --host ssh://$(GATEWAY) build -t dkbnz/gateway-link:latest ./src/gateway-link/
	docker build -t fractalnetworks/gateway-client:latest ./src/client-link/
	docker build -t fractalnetworks/gateway-cli:latest ./src/create-link/

gateway:
	docker --host ssh://$(GATEWAY) network create gateway || true
	docker --host ssh://$(GATEWAY) run \
		--network gateway \
		--restart unless-stopped \
		-p 80:80 \
		-p 443:443 \
		-e NGINX_ENVSUBST_OUTPUT_DIR=/etc/nginx \
		-it -d dkbnz/gateway:latest

link:
	docker run -v /<your-home-directory>/.ssh:/root/.ssh --rm -it fractalnetworks/gateway-cli:latest $(GATEWAY) $(FQDN) $(EXPOSE)
