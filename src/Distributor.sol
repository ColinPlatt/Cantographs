// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@Openzeppelin/access/Ownable.sol";
import "./Cantographs.sol";

contract Distributor is Ownable {

    uint256 public constant MAX_MINT = 1000;
    uint256 public constant MINT_COST = 125 ether;
    
    Cantographs public immutable cantoGraphs;  // we can only set this once, if we mess up we need to redeploy and update the NFT contract
    mapping(address => uint8) public mintedByAddress;

    uint16[1000] public ids;
    uint16 private index;
    
    constructor(
        address _cantoGraphs
    ) {
        cantoGraphs = Cantographs(_cantoGraphs);
    }

    // Owner can withdraw CANTO sent to this contract
    function withdraw(uint256 amount) external onlyOwner{
        bool success;
        address to = owner();

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    function _pickPseudoRandomUniqueId(uint256 seed) private returns (uint256 id) {
        uint256 len = ids.length - index++;
        require(len > 0, 'Mint closed');
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(seed, block.timestamp))) % len;
        id = ids[randomIndex] != 0 ? ids[randomIndex] : randomIndex;
        ids[randomIndex] = uint16(ids[len - 1] == 0 ? len - 1 : ids[len - 1]);
        ids[len - 1] = 0;
    }

    function mint(uint8 amt) public payable {
        // owner not subjected to maxes
        if(msg.sender != owner()){
            require(amt <= 10 , "Max 10 mints");
            require(mintedByAddress[msg.sender]+amt <= 10, "Max 10 per address");
            require(msg.value >= amt * MINT_COST, "Insufficient payment");
            mintedByAddress[msg.sender] += amt;
        }

        for(uint256 i = 0; i<amt; ++i) {

            cantoGraphs.mintFromDistributor(msg.sender, _pickPseudoRandomUniqueId(uint160(msg.sender)*i)+1);
        }

    }

}