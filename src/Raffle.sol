//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A sample Raffle contract
 * @author GideonOv
 * @notice This contract is a simple implementation of a raffle system.
 * @dev Implements Chainlink VRFv2.5 for random number generation.
 * @dev Uses a subscription model for funding VRF requests.
 * @dev Subsription ID is set to 70727098758823347346317768322724523984682348539548870321631433152369211671597.
 * @dev Subscription ID can be changed in the HelperConfig.s.sol script.
 * @dev This contract is for educational purposes and should not be used in production.
 * @dev I would expect that anyone using this contract should have profound knowledge in smart contract develpoment..
 * @dev ..specifically in solidity and foundry
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error Raffle__InsufficentEntranceFeePaid(uint256 fee, uint256 paid);
    error Raffle__TransferFailed(address transferTo, uint256 amount);
    error Raffle__RaffleNotOpen();
    error Raffle__OwnerCannotEnterRaffle();
    error Raffle__RaffleAlreadyInSession();
    error Raffle__OnlyRaffleOwnerCanEndRaffle();

    /* Type Declarations */
    enum RaffleState {
        CLOSED, // 0
        OPEN // 1

    }

    /* State Variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable private s_raffleOwner;
    address payable private s_previousRaffleOwner;
    uint256 private s_entranceFee;
    uint256 private s_rafflebalance;
    address payable[] private s_players;
    address payable[] private s_previousSessionPlayers;
    address private s_recentWinner;
    RaffleState private s_raffleState; // start as CLOSED

    /* Events */
    event RaffleOpened(address indexed owner, uint256 indexed fee);
    event RaffleEntered(address indexed player);
    event RaffleWinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    // The VRFConsumerBaseV2Plus contract inherited by this contract takes a..
    // ..vrfcoordinator into its constructor
    constructor(
        address vrfCoodinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoodinator) {
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        
        s_raffleState = RaffleState.CLOSED;
    }


    function openRaffle(uint256 raffleEntranceFee) external {
        if (s_raffleOwner != payable(address(0))) {
            revert Raffle__RaffleAlreadyInSession();
        }
        s_raffleOwner = payable(msg.sender);
        s_raffleState = RaffleState.OPEN;
        s_entranceFee = raffleEntranceFee;
        emit RaffleOpened(s_raffleOwner, s_entranceFee);
    }


    function enterRaffle() external payable {
        if (msg.sender == s_raffleOwner) {
            revert Raffle__OwnerCannotEnterRaffle();
        }
        if (msg.value < s_entranceFee) {
            revert Raffle__InsufficentEntranceFeePaid(s_entranceFee, msg.value);
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }


    function endRaffle() external {
        if (msg.sender != s_raffleOwner) {
            revert Raffle__OnlyRaffleOwnerCanEndRaffle();
        }

        s_raffleState = RaffleState.CLOSED; // Set the raffle state to CLOSED
        
        if (s_players.length == 0) {
            // Reset the Raffle
            s_raffleOwner = payable(address(0));
            s_entranceFee = 0;
            return;
        }

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
        s_previousSessionPlayers = s_players;
        s_players = new address payable[](0); // Reset the players array
        emit RaffleWinnerPicked(recentWinner);

        // Interactions (External Contract Interaction)
        uint256 ownerFee = address(this).balance * 1e17 / 1e18; // 10% paid to raffle owner
        (bool successOne,) = s_raffleOwner.call{value: ownerFee}("");
        if (successOne) {
            (bool successTwo,) = recentWinner.call{value: address(this).balance}("");
            if (!successTwo) {
                revert Raffle__TransferFailed(s_recentWinner, address(this).balance);
            }
        } else {
            revert Raffle__TransferFailed(s_raffleOwner, ownerFee);
        }

        // Reset the Raffle
        s_previousRaffleOwner = s_raffleOwner;
        s_raffleOwner = payable(address(0));
        s_entranceFee = 0;
    }

    /**
     * Getter Functions
     */
    function getRaffleOwner() external view returns(address) {
        return s_raffleOwner;
    }

    function getRafflePreviousOwner() external view returns(address) {
        return s_previousRaffleOwner;
    }

    function getEntranceFee() external view returns(uint256) {
        return s_entranceFee;
    }

    function getRaffleState() external view returns(RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns(address) {
        return (s_players[indexOfPlayer]);
    }

    function getPlayerFromPreviousSession(uint256 indexOfPlayer) external view returns(address) {
        return (s_previousSessionPlayers[indexOfPlayer]);
    }

    function getPlayersCount() external view returns(uint256) {
        return s_players.length;
    }
    

    function getRecentWinner() external view returns(address) {
        return s_recentWinner;
    }
}
