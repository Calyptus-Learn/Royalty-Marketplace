// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface ICalyptusNFT {
    function getRoyaltyFee() external view returns (uint256);

    function getRoyaltyRecipient() external view returns (address);
}
