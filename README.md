# RealState Smart Contract

This Solidity smart contract implements a decentralized real estate token system. Token holders own shares of real estate, and locataries (tenants) pay rent in Ether, which is then distributed to the token holders based on their ownership percentages.

## Features

- **ERC20 Token**: The contract uses an ERC20-compliant token, where each token represents a share of real estate ownership.
- **Access Control**: The contract includes role-based access control to ensure only authorized addresses can mint tokens or modify important parameters.
- **Rent Payments**: Locataries can pay rent in Ether, which is distributed to token holders according to their ownership shares.
- **Rent Distribution**: Rent received by the contract is automatically distributed to token holders in proportion to their token holdings.
- **Withdrawal**: Administrators can withdraw Ether from the contract.
- **Event Logging**: Various events are emitted for transparency and tracking of key actions.

## Contract Overview

### State Variables

- `totalSupplyTokens`: Total number of tokens minted.
- `totalRentReceived`: Total amount of rent received in Ether.
- `valueToPay`: The Ether amount that locataries are required to pay as rent.
- `rentReceived`: Mapping of addresses to the rent they've received.
- `isTokenHolder`: Tracks whether an address holds tokens.
- `isLocatary`: Tracks whether an address is a locatary (tenant).
- `tokenHolders`: An array storing the addresses of all token holders.

### Roles

- **MINTER_ROLE**: Addresses with this role can mint new tokens.
- **DEFAULT_ADMIN_ROLE**: The admin role can configure locataries and withdraw Ether from the contract.

### Functions

#### `mint(uint256 amount)`
Mints a specified number of tokens to the caller. Only addresses with the `MINTER_ROLE` can call this function.

#### `setValueToPay(uint256 etherAmount)`
Sets the amount of Ether that locataries need to pay for rent. Only the admin can call this function.

#### `payRent()`
Allows locataries to pay rent in Ether. The Ether is then distributed to the token holders based on their ownership percentages.

#### `withdraw(uint256 amount)`
Allows the admin to withdraw a specified amount of Ether from the contract balance.

#### `transferRealStateTokens(address to, uint256 amount)`
Transfers real estate tokens from one holder to another. If the recipient is not already a token holder, they are added to the list of holders.

#### `calculateOwnershipPercentage(address account)`
Calculates and returns the ownership percentage of a specific account based on its token balance.

#### `setLocatary(address locatary, bool status)`
Sets or revokes the locatary status of an address. Only the admin can call this function.

#### `balanceOfContractInEther()`
Returns the contract’s current Ether balance.

### Events

- `RealStatePart(sender, receiver, amount)`: Emitted when tokens are transferred between accounts.
- `RentPaid(locatary, amount, timestamp)`: Emitted when a locatary pays rent.
- `RentDistributed(totalRent, timestamp)`: Emitted when rent is distributed to token holders.
- `RentDistributedToHolder(holder, amount)`: Emitted when rent is distributed to a specific holder.
- `ValueToPaySet(amount, timestamp)`: Emitted when the rent amount is set.
- `Withdraw(owner, amount, timestamp)`: Emitted when an admin withdraws Ether from the contract.

### How It Works

1. **Minting Tokens**: The admin mints tokens using the `mint` function. These tokens represent ownership in the real estate property.
2. **Setting Rent**: The admin sets the rent amount in Ether using the `setValueToPay` function.
3. **Locatary Pays Rent**: Locataries (tenants) pay rent in Ether by calling the `payRent` function.
4. **Rent Distribution**: The rent is automatically distributed to token holders based on their ownership percentages. Each holder's share of the rent is sent to their wallet.
5. **Withdrawing Funds**: The admin can withdraw funds from the contract using the `withdraw` function.

### How to Use

1. Clone this repository:
    ```bash
    git clone https://github.com/your-username/realstate-contract.git
    cd realstate-contract
    ```

2. Compile and deploy the contract using a development framework like [Hardhat](https://hardhat.org/) or [Truffle](https://www.trufflesuite.com/).

3. Make sure to set up roles and assign the `MINTER_ROLE` to the admin account for minting tokens.

4. The contract can interact with locataries and token holders through functions like `payRent()` and `mint()`.

