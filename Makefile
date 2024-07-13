include .env

deploy:
	forge script script/GnosisPayInfraDeployment.s.sol \
	--rpc-url gnosis \
	--via-ir \
	-vvvv \
	--broadcast \
	--verify \
	--chain gnosis

deployDry:
	forge script script/GnosisPayInfraDeployment.s.sol \
	--rpc-url gnosis \
	--via-ir \
	-vvvv

deploySingleton:
	forge script script/SingletonVirtualModuleDeployment.s.sol \
	--rpc-url gnosis \
	--via-ir \
	-vvvv \
	--broadcast \
	--verify \
	--chain gnosis

deploySingletonDry:
	forge script script/SingletonVirtualModuleDeployment.s.sol \
	--rpc-url gnosis \
	--via-ir \
	-vvvv

deployAnvil:
	forge script script/GnosisPayInfraDeployment.s.sol \
	--rpc-url http://127.0.0.1:8545 \
	--broadcast \
	--legacy \
	-vvvv

startAnvil:
	anvil \
	--code-size-limit 1000000 \
	--fork-url gnosis \
	--gas-price 0

verifyTenderly:
	forge verify-contract ${VMODULE_ADDRESS} \
	RoboSaverVirtualModule \
	--etherscan-api-key ${TENDERLY_ACCESS_TOKEN} \
	--verifier-url ${TENDERLY_VERIFIER_URL} \
	--chain gnosis \
	--via-ir \
	--watch
