GATEWAY_URL ?= https://scarlet:9443/v1
KEY_REF     ?= op://private/agent-gateway-api-key/password

.PHONY: gateway-test
gateway-test: ## GET /v1/models on Agentgateway with the 1Password key (key never printed)
	@set -euo pipefail; \
	key="$$(op read '$(KEY_REF)')"; \
	printf 'header = "Authorization: Bearer %s"\n' "$$key" | \
	  curl -fsS --max-time 15 -K - -o /dev/null -w 'HTTP %{http_code} from $(GATEWAY_URL)/models\n' '$(GATEWAY_URL)/models'
