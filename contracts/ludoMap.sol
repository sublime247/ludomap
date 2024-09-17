// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract LudoMap {
    struct Player {
        address playerAddress;
        uint8[4] pieces;  // 4 pieces for each player
        bool hasWon;      // Whether the player has won
    }

    uint8 constant board_tile = 52;  // Simplified board size (Ludo has 52 tiles)
    uint8 constant startingPoint = 0;  // Starting position for all pieces
    uint8 constant steps_home = 51;  // Home position after completing the circle

    address[] public players;   // List of players
    mapping(address => Player) public playerInfo;  // Player data
    uint8 public currentTurn;  // Track whose turn it is
    bool public gameStarted;  // Check if the game has started
    uint8 public numPlayers;  // Number of players registered


    /*------------Algorithm to roll a die-----------------*/

    function rollDice() public  returns (uint8) {
        require(players[currentTurn] == msg.sender, "It's not your turn!");

        uint256 randomHash = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender
        )));

        uint8 diceRoll = uint8(randomHash % 6) + 1;  // Dice result between 1 and 6

        // After rolling, move the piece and check victory condition
        movePiece(diceRoll);

        // If the player rolls a 6, they get another turn
        if (diceRoll != 6) {
            nextTurn();  // Move to the next player's turn
        }

        return diceRoll;
    }

    // Register a player
    function registerPlayer() public {
        require(numPlayers < 4, "Max 4 players allowed!");
        require(playerInfo[msg.sender].playerAddress == address(0), "Player already registered!");

        players.push(msg.sender);
        playerInfo[msg.sender] = Player({
            playerAddress: msg.sender,
            pieces: [startingPoint, startingPoint, startingPoint, startingPoint],
            hasWon: false
        });
        numPlayers++;
    }

    // Move a piece (simplified: move the first piece that can move)
    function movePiece(uint8 diceRoll) private {
        Player storage player = playerInfo[msg.sender];

        for (uint8 i = 0; i < 4; i++) {
            if (canMovePiece(player.pieces[i], diceRoll)) {
                player.pieces[i] += diceRoll;

                // Check if the piece has reached the home position
                if (player.pieces[i] >= steps_home) {
                    player.pieces[i] = steps_home;
                }

                // Check for a win condition (all pieces in home)
                if (hasPlayerWon(player)) {
                    player.hasWon = true;
                    gameStarted = false;
                }

                break;  // Only move one piece per turn
            }
        }
    }

    // Check if the piece can move based on its current position and dice roll
    function canMovePiece(uint8 piecePosition, uint8 diceRoll) private pure returns (bool) {
        return piecePosition + diceRoll <= steps_home;
    }

    // Check if all pieces are in the home position (player wins)
    function hasPlayerWon(Player memory player) private pure returns (bool) {
        for (uint8 i = 0; i < 4; i++) {
            if (player.pieces[i] != steps_home) {
                return false;
            }
        }
        return true;
    }

    // Move to the next player's turn
    function nextTurn() private {
        currentTurn = (currentTurn + 1) % numPlayers;
    }

}
