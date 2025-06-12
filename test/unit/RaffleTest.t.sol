// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Raffle} from "src/Raffle.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "script/HelperConfig.s.sol";


contract RaffleTest is Test, CodeConstants {
    Raffle public raffle;
    HelperConfig public helperConfig;

    address vrfCoordinator;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    uint256 subscriptionId;

    address public OWNER = makeAddr("owner");
    address public PLAYER = makeAddr("player");
    address public PLAYER1 = makeAddr("player1");

    uint256 public constant ENTRANCE_FEE = 1 ether;
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    /* Events */
    event RaffleOpened(address indexed owner, uint256 indexed fee);
    event RaffleEntered(address indexed player);
    event RaffleWinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        vm.deal(PLAYER1, 1e19); // Fund 10 ETH
    }


    ////////////////////////////////////////////////////
    /////////////  INITIALIZATION TESTS  ///////////////
    ////////////////////////////////////////////////////

    function testRaffleDefaultStateIsClosed() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.CLOSED);
    }

    function testRaffleHasNoDefaultOwner() public view {
        assert(raffle.getRaffleOwner() == address(0));
    }


    ////////////////////////////////////////////////////
    //////////////  OPEN RAFFLE TESTS  /////////////////
    ////////////////////////////////////////////////////

    modifier raffleOpened() {
        vm.prank(OWNER);
        raffle.openRaffle(ENTRANCE_FEE);
        _;
    }

    function testOpenRaffleCannotBeCalledWhenRaffleIsInSession() public raffleOpened {
        // Arrange / Act / Assert
        vm.expectRevert(Raffle.Raffle__RaffleAlreadyInSession.selector);
        vm.prank(PLAYER);
        raffle.openRaffle(ENTRANCE_FEE);
    }

    function testOpenRaffleSetsAnOwner() public raffleOpened {
        assert(raffle.getRaffleOwner() != address(0));
    }
    
    function testOpenRaffleSetsRaffleStateToOpen() public raffleOpened {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testOpenRaffleSetsAnEntranceFee() public raffleOpened {
        uint256 defaultEntranceFee = 0;
        assert(raffle.getEntranceFee() > defaultEntranceFee);
    }

    function testOpenRaffleEmitsARaffleOpenedEvent() public {
        // Arrange / Act
        vm.prank(OWNER);
        vm.expectEmit(true, true, false, false, address(raffle));
        emit RaffleOpened(OWNER, ENTRANCE_FEE);
        // Assert
        raffle.openRaffle(ENTRANCE_FEE);
    }


    ////////////////////////////////////////////////////
    //////////////  ENTER RAFFLE TESTS  /////////////////
    ////////////////////////////////////////////////////

    function testEnterRaffleCannotBeCalledByRaffleOwner() public raffleOpened {
        // Arrange
        uint256 balance = 5 ether;
        // Act
        vm.deal(OWNER, balance);
        vm.prank(OWNER);
        // Assert
        vm.expectRevert(Raffle.Raffle__OwnerCannotEnterRaffle.selector);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
    }

    function testEnterRaffleRejectsPaymentWhenEntranceFeeIsNotEnough() public raffleOpened {
        // Arrange
        uint256 fee = raffle.getEntranceFee();
        uint256 payment = 0.1 ether;
        // Act
        vm.prank(PLAYER);
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__InsufficentEntranceFeePaid.selector,
                fee,
                payment
            ));
        // Assert
        raffle.enterRaffle{value: payment}();
    }

    function testEnterRaffleRejectsEntrantsWhenRaffleIsClosed() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
    }

    function testEnterRaffleRecordsPlayersWhenTheyEnter() public raffleOpened {
        // Arrange
        vm.prank(PLAYER);
        // Act
        raffle.enterRaffle{value: ENTRANCE_FEE}();
        address playerRecorded = raffle.getPlayer(0);
        // Assert
        assert(playerRecorded == PLAYER);
    }

    function testEnterRaffleEmitsRaffleEnteredEventWhenNewPlayerEnters() public raffleOpened {
        // Arrange
        vm.prank(PLAYER);
        // Act
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        // Assert
        raffle.enterRaffle{value: ENTRANCE_FEE}();
    }


    ////////////////////////////////////////////////////
    //////////////  END RAFFLE TESTS  //////////////////
    ////////////////////////////////////////////////////


    function testEndRaffleCanOnlyBeCalledByRaffleOwner() public raffleOpened {
        vm.expectRevert(Raffle.Raffle__OnlyRaffleOwnerCanEndRaffle.selector);
        vm.prank(PLAYER);
        raffle.endRaffle();
    }

    function testEndRaffleSetsTheRaffleStateToClosed() public raffleOpened {
        vm.prank(OWNER);
        raffle.endRaffle();
        assert(raffle.getRaffleState() == Raffle.RaffleState.CLOSED);
    }

    function testEndRaffleResetsTheRaffleWithoutPickingAWinnerIfThereAreNoPlayers() public raffleOpened {
        vm.prank(OWNER);
        raffle.endRaffle();
        assert(raffle.getRaffleOwner() == address(0));
        assert(raffle.getEntranceFee() == 0);
    }

    function testEndRaffleEmitsRequestId() public raffleOpened {
        // Arrange / Act
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
        vm.recordLogs();
        vm.prank(OWNER);
        raffle.endRaffle();

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        //console2.log("Request Id is: ", uint256(requestId));

        assert(uint256(requestId) > 0);
    }


    
    ////////////////////////////////////////////////////
    /////////  FULFILL RANDOM WORDS TESTS  ////////////
    ////////////////////////////////////////////////////


    modifier skipForked() {
        if (block.chainid != LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }

    modifier fulfillRandomWordsSetUp() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
        vm.prank(PLAYER1);
        raffle.enterRaffle{value: 5 ether}();
        _;
    }


    function testFulfillRandomWordsCanOnlyBeCalledAfterRaffleEnded(uint256 randomRequestId) public skipForked {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
    }

    function testFulfillRandomWordsPicksAWinner() public raffleOpened skipForked fulfillRandomWordsSetUp {
        vm.recordLogs();
        vm.prank(OWNER);
        raffle.endRaffle();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));
        address recentWinner = raffle.getRecentWinner();

        assert(recentWinner == raffle.getPlayerFromPreviousSession(0) || recentWinner == raffle.getPlayerFromPreviousSession(1));
    }

    function testFulfilRandomWordsPaysTenPercentToTheRaffleOwner() public raffleOpened skipForked fulfillRandomWordsSetUp {
        // Arrange
        uint256 initialOwnerBalance = address(OWNER).balance;
        uint256 balance = address(raffle).balance;
        uint256 ownerPayment = balance * 1e17 / 1e18;
        // console2.log("Raffle balance is: ", balance);
        // console2.log("Owner's Payment is: ", ownerPayment);

        // Act
        vm.recordLogs();
        vm.prank(OWNER);
        raffle.endRaffle();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        // Assert
        uint256 finalOwnerBalance = address(raffle.getRafflePreviousOwner()).balance;
        assert(finalOwnerBalance == ownerPayment + initialOwnerBalance);
    }

    function testFulfilRandomWordsResetsTheRaffleOwnerAndEntranceFee() public raffleOpened skipForked fulfillRandomWordsSetUp {
        vm.recordLogs();
        vm.prank(OWNER);
        raffle.endRaffle();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        assert(raffle.getRaffleOwner() == address(0));
        assert(raffle.getEntranceFee() == 0);
    }

}