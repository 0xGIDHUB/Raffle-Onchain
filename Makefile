-include .env

.PHONY: all test deploy

build:; forge build

test:; forge test

install:
	@forge install cyfrin/foundry-devops@0.2.2 --no-commit && forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 --no-commit && forge install foundry-rs/forge-std@v1.8.2 --no-commit && forge install transmissions11/solmate@v6 --no-commit

anvil:; @anvil

test-anvil:
	@forge test

test-sepolia:
	@forge test --rpc-url $(SEPOLIA_RPC_URL)

deploy-anvil:
	@forge script script/DeployRaffle.s.sol:DeployRaffle --private-key $(ANVIL_PRIVATE_KEY) --rpc-url $(ANVIL_RPC_URL) --broadcast 

deploy-sepolia:
	@forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $(SEPOLIA_RPC_URL) --account default --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv -i 1
