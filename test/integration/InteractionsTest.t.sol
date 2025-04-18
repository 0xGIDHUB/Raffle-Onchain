// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// Testing All DeployScripts And How Contracts Interact With Each Other

import {Test} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract InteractionsTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;
    address public DEFAULT_PLAYER = makeAddr("defaultplayer");
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    uint256 subscriptionId;

    uint256 private constant STARTING_PLAYER_BALANCE = 1 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        vm.deal(DEFAULT_PLAYER, STARTING_PLAYER_BALANCE);

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;
    }

    function testPlayerCanEnterRaffle() public {
        // Arrange / Act / assert
        vm.prank(DEFAULT_PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        assert(address(raffle).balance == entranceFee);
        assert(raffle.getPlayer(0) == DEFAULT_PLAYER);
        assert(raffle.getPlayersCount() == 1);
    }

    // function testMultiplePlayersCanEnterRaffle() public {
    //     // Arrange
    //     // Act
    //     // Assert
    // }
}