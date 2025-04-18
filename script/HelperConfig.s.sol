// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    /* VRF Mock Values */
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE = 1e9;
    // LINK/ETH Price
    int256 public MOCK_WEI_PER_UINT_LINK = 4e15;

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

/**
 * @dev The HelperConfig is for the purpose of setting different..
 * @dev ..configuration parameters based on the block chain you..
 * @dev ..are deploying the raffle contract to.
 * @dev Configurations have already been made for sepolia testnet..
 * @dev ..and anvil local network.
 * @dev To make a new configuration, add a new NetworkConfig struct..
 * @dev ..with a function and a constructor just like is done with..
 * @dev ..the 'getSepoliaETHConfig()'
 * 
 */
contract HelperConfig is CodeConstants, Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        uint256 subscriptionId;
        address link;
        address account;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaETHConfig();
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilETHConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaETHConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether, // 1e16
            interval: 30, // 30 seconds
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B, // Sepolia VRF Coordinator
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500000, // 500,000 gas
            subscriptionId: 70727098758823347346317768322724523984682348539548870321631433152369211671597,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0x96C305c25B8E5993bE07b1148B47f8E54744De76
        });
    }

    function getOrCreateAnvilETHConfig() public returns (NetworkConfig memory) {
        // Check to see if we set an active network config
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        // Deploy mocks and such
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock =
            new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE, MOCK_WEI_PER_UINT_LINK);
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether, // 1e16
            interval: 30, // 30 seconds
            vrfCoordinator: address(vrfCoordinatorMock), // Sepolia VRF Coordinator
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, // dosent matter (mock)
            callbackGasLimit: 500000, // 500,000 gas
            subscriptionId: 0,
            link: address(linkToken),
            account: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 // Anvil Account Address (0)
        });
        return localNetworkConfig;
    }
}
