// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Importing the ERC20 token standard and AccessControl functionalities from OpenZeppelin library
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// Contract declaration, inheriting from ERC20 and AccessControl
contract RealState is ERC20, AccessControl {
    // Define a constant role for minting tokens
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // State variables to track total tokens and rent
    uint256 public totalSupplyTokens;   // Total supply of minted tokens
    uint256 public totalRentReceived;    // Total rent received by the contract
    uint256 public valueToPay;           // The fixed amount of Ether required for rent

    // Mappings to track rent received and statuses of token holders and locataries
    mapping(address => uint256) public rentReceived; // Amount of rent received by each address
    mapping(address => bool) public isTokenHolder;    // Status of whether an address holds tokens
    mapping(address => bool) public isLocatary;      // Status of whether an address is a locatary

    // List to store addresses of token holders
    address[] public tokenHolders;

    // Events for logging important actions
    event RealStatePart(address indexed sender, address indexed receiver, uint256 amount); // Token transfer event
    event RentPaid(address indexed locatary, uint256 amount, uint256 timestamp);           // Event for rent payment
    event RentDistributed(uint256 totalRent, uint256 timestamp);                           // Event for rent distribution
    event RentDistributedToHolder(address indexed holder, uint256 amount);                  // Event for individual rent distribution
    event ValueToPaySet(uint256 amount, uint256 timestamp);                                // Event for setting rent value
    event Withdraw(address indexed owner, uint256 amount, uint256 timestamp);               // Event for Ether withdrawal

    // Constructor to initialize the token and set roles
    constructor() ERC20("RealState", "RST") {
        // Grant default admin and minter roles to the contract deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    // Function to mint new tokens
    function mint(uint256 amount) public onlyRole(MINTER_ROLE) {
        // Mint the specified amount of tokens to the caller
        _mint(msg.sender, amount);
        // Update total supply of tokens
        totalSupplyTokens += amount;
        // Mark the caller as a token holder
        isTokenHolder[msg.sender] = true;
        // Distribute the newly minted tokens from the owner
        _distributeTokensFromOwner(amount);
    }

    // Internal function to distribute tokens from the owner's balance to token holders
    function _distributeTokensFromOwner(uint256 amount) internal {
        // Ensure there are tokens to distribute
        require(totalSupplyTokens > 0, "No tokens to distribute");
        // Check if the owner has enough tokens to distribute
        require(balanceOf(msg.sender) >= amount, "Owner has insufficient tokens");

        // Loop through all token holders to distribute tokens based on ownership percentage
        for (uint256 i = 0; i < tokenHolders.length; i++) {
            address holder = tokenHolders[i];
            // Skip the owner
            if (holder != msg.sender) {
                // Calculate the percentage of ownership of the holder
                uint256 holderPercentage = calculateOwnershipPercentage(holder);
                // Calculate the holder's share of tokens
                uint256 holderShare = (amount * holderPercentage) / 100;

                // If the holder's share is greater than zero, transfer tokens
                if (holderShare > 0) {
                    _transfer(msg.sender, holder, holderShare); // Transfer tokens from the owner to the holder
                    emit RealStatePart(msg.sender, holder, holderShare); // Emit event for token transfer
                }
            }
        }
    }

    // Function to set the value that locataries must pay for rent
    function setValueToPay(uint256 etherAmount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        valueToPay = etherAmount * 1e18; // Convert Ether to Wei (1 Ether = 10^18 Wei)
        require(valueToPay > 0, "Set a value greater than 0 ether"); // Ensure the value is positive
        emit ValueToPaySet(valueToPay, block.timestamp); // Emit event when value is set
    }

    // Function for locataries to pay rent
    function payRent() public payable {
        require(isLocatary[msg.sender], "Only locataries can pay rent"); // Check if the caller is a locatary
        require(msg.value == valueToPay, "Incorrect value. Review the correct rent"); // Ensure the correct Ether amount is sent

        totalRentReceived += msg.value; // Update total rent received
        emit RentPaid(msg.sender, msg.value, block.timestamp); // Emit event for rent payment
        _distributeRent(msg.value); // Distribute the rent to token holders
    }

    // Internal function to distribute rent to token holders
    function _distributeRent(uint256 totalRent) internal {
        require(totalSupplyTokens > 0, "No tokens have been minted yet"); // Ensure tokens exist

        // Loop through all token holders to distribute rent based on ownership percentage
        for (uint256 i = 0; i < tokenHolders.length; i++) {
            address holder = tokenHolders[i];
            uint256 holderPercentage = calculateOwnershipPercentage(holder); // Calculate ownership percentage
            uint256 holderShare = (totalRent * holderPercentage) / 100; // Calculate holder's share of rent

            // If the holder's share is greater than zero, attempt to send Ether
            if (holderShare > 0) {
                (bool success, ) = holder.call{value: holderShare}(""); // Send Ether to the holder
                if (success) {
                    rentReceived[holder] += holderShare; // Update amount of rent received by the holder
                    emit RentDistributedToHolder(holder, holderShare); // Emit event for rent distribution
                } else {
                    // Log error instead of reverting
                    emit RentDistributedToHolder(holder, 0); // Emit with 0 to indicate failure
                }
            }
        }

        emit RentDistributed(totalRent, block.timestamp); // Emit event for total rent distribution
    }

    // Function to transfer RealState tokens to another address
    function transferRealStateTokens(address to, uint256 amount) public {
        require(balanceOf(msg.sender) >= amount, "Insufficient tokens"); // Check if the sender has enough tokens
        _transfer(msg.sender, to, amount); // Transfer tokens from sender to recipient

        // If the recipient is not already a token holder, mark them as one
        if (!isTokenHolder[to]) {
            isTokenHolder[to] = true; // Mark as a token holder
            tokenHolders.push(to); // Add the recipient to the list of token holders
        }

        emit RealStatePart(msg.sender, to, amount); // Emit event for token transfer
    }

    // Function to withdraw Ether from the contract
    function withdraw(uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(amount > 0, "Amount must be greater than 0"); // Ensure the withdrawal amount is positive
        require(amount <= address(this).balance, "Insufficient contract balance"); // Ensure sufficient balance in the contract

        (bool success, ) = msg.sender.call{value: amount}(""); // Attempt to send Ether to the caller
        require(success, "Transfer failed"); // Ensure the transfer was successful

        emit Withdraw(msg.sender, amount, block.timestamp); // Emit event for withdrawal
    }

    // Internal function to convert uint256 to string
    function _uintToString(uint256 v) internal pure returns (string memory str) {
        uint256 len = 0;
        uint256 tempV = v;
        if (v == 0) {
            return "0"; // Return "0" if the input is zero
        }
        while (tempV != 0) {
            len++; // Count the number of digits
            tempV /= 10; // Reduce the number for the next iteration
        }
        bytes memory bstr = new bytes(len); // Create a byte array to store the string
        uint256 k = len - 1;
        while (v != 0) {
            bstr[k--] = bytes1(uint8(48 + v % 10)); // Convert digit to character
            v /= 10; // Reduce the number for the next iteration
        }
        str = string(bstr); // Convert byte array to string
    }

    // Function to calculate the ownership percentage of a given account
    function calculateOwnershipPercentage(address account) public view returns (uint256) {
        uint256 accountBalance = balanceOf(account); // Get the balance of the account
        return (accountBalance * 100) / totalSupplyTokens; // Calculate ownership percentage
    }

    // Function to set the status of a locatary
    function setLocatary(address locatary, bool status) public onlyRole(DEFAULT_ADMIN_ROLE) {
        isLocatary[locatary] = status; // Update the locatary status
    }

    // Function to get the contract's Ether balance
    function balanceOfContractInEther() public view returns (uint256) {
        return address(this).balance; // Return the balance of the contract in Ether
    }

    // Fallback function to receive Ether payments
    receive() external payable {
        require(isLocatary[msg.sender], "Only locataries can pay rent"); // Ensure the sender is a locatary
        payRent(); // Call payRent function to process the payment
    }
}
