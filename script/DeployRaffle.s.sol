// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";

contract DeployRaffle is Script {
    function run() public {
        deployContract();
    }

    /**
     * @dev This is the function that deploys the Raffle contract to the blockchain.
     * @dev The following occurs before the contract can be deployed:
     * 1. The helperConfig gets the configuration for the current network
     * 2. If there is no VRF subscription in the configuration, a new one is created
     * 3. The subscription is funded with LINK
     * 4. The raffle contract is deployed with the configuration parameters
     * 5. A raffle contract is added to the VRF subscription as a consumer
     * @param - ignored
     * @return upkeepNeeded - true if its time to pick a winner
     * @return - ignored
     */
    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        // local -> Deploy Mock
        // sepolia -> Use existing VRF Coordinator
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            // create subscription
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) = createSubscription.createSubscription(config.vrfCoordinator, config.account);

            // Fund subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinator,
                config.subscriptionId,
                config.link,
                config.account
            );
        }

        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId, config.account);

        return (raffle, helperConfig);
    }
}
