// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A sample Raffle contract
 * @author GideonOv
 * @notice This contract is a simple implementation of a raffle system.
 * @dev Implements Chainlink VRFv2.5 for random number generation.
 * @dev Implements Chainlink automation for automatic winner selection.
 * @dev Uses a subscription model for funding VRF requests.
 * @dev Subsription ID is set to 70727098758823347346317768322724523984682348539548870321631433152369211671597.
 * @dev Subscription ID can be changed in the HelperConfig.s.sol script.
 * @dev A Chainlink Upkeep should be manually registered on the Raffle contract using custom based logic.
 * @dev This contract is for educational purposes and should not be used in production.
 * @dev I would expect that anyone using this contract should have profound knowledge in smart contract develpoment..
 * @dev ..specifically in solidity and foundry
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error Raffle__SendMoreETHToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);

    /* Type Declarations */
    enum RaffleState {
        OPEN, // 0
        CALCULATING // 1

    }

    /* State Variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    uint256 private s_rafflebalance;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState; // start as OPEN

    /* Events */
    event RaffleEntered(address indexed player);
    event RaffleWinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    // The VRFConsumerBaseV2Plus contract inherited by this contract takes a..
    // ..vrfcoordinator into its constructor
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoodinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoodinator) {
        i_interval = interval;
        i_entranceFee = entranceFee;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH to enter the raffle");
        // require(msg.value >= i_entranceFee, Raffle__SendMoreETHToEnterRaffle());
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreETHToEnterRaffle();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    /**
     * * @dev This function should only be called by a Chainlink Upkeep
     * @dev This is the function that the Chainlink nodes will call to see if the lottery is ready to have a winner picked.
     * @dev The following should be true:
     * 1. The time interval of a raffle duration has passed
     * 2. The raffle is in the OPEN state
     * 3. The contract has ETH
     * 4. The contract has players
     * 5. Implicitly, the subscription has LINK
     * @param - ignored
     * @return upkeepNeeded - true if its time to pick a winner
     * @return - ignored
     */
    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "");
    }

    /**
     * @dev This function should only be called by a Chainlink Upkeep
     */
    function performUpkeep(bytes calldata /* performData */ ) external {
        // check if the duration of the raffle has ended
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        s_raffleState = RaffleState.CALCULATING; // Set the raffle state to CALCULATING

        // Get the RandomWordsRequest struct from the VRFV2PlusClient library
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash, // Maximum gas price for the request
            subId: i_subscriptionId, // Subscription ID for funding the request
            requestConfirmations: REQUEST_CONFIRMATIONS, // Mumber of confirmations to wait before responding
            callbackGasLimit: i_callbackGasLimit, // The limit for how much gas to use for the callback request
            numWords: NUM_WORDS, // How many random values to request
            extraArgs: VRFV2PlusClient._argsToBytes(
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        emit RequestedRaffleWinner(requestId); // This is redundant, but we are using it for testing purposes
    }

    /**
     * @dev This function can only be called by the Chainlink vrf coordinator
     */
    function fulfillRandomWords(uint256, /* requestId */ uint256[] calldata randomWords) internal override {
        // Checks
        // Effects (Internal Contract State)
        uint256 indexOfWinner = randomWords[0] % s_players.length; // Get a number x for 0 <= x < s_players.length
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN; // Set the raffle state back to OPEN
        s_players = new address payable[](0); // Reset the players array
        s_lastTimeStamp = block.timestamp; // Reset the last time stamp
        emit RaffleWinnerPicked(recentWinner);

        // Interactions (External Contract Interaction)
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /**
     * Getter Functions
     */
    function getEntranceFee() external view returns(uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns(RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns(address) {
        return (s_players[indexOfPlayer]);
    }

    function getPlayersCount() external view returns(uint256) {
        return s_players.length;
    }

    function getLastTimeStamp() external view returns(uint256) {
        return s_lastTimeStamp;
    }

    function getRecentWinner() external view returns(address) {
        return s_recentWinner;
    }
}
