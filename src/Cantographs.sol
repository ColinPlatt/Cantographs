// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@Openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";
import "@Openzeppelin/token/common/ERC2981.sol";
import "@Openzeppelin/access/Ownable.sol";


contract Cantographs is ERC721Enumerable, ERC2981, Ownable {
    
    uint256 public constant MAX_ID = 1000;

    address private royaltyReceiver = 0xe591a66238CF6FB473089d75bc8cB3DaEC3d5241;
    string public baseURI;
    address public distributor;

    constructor(string memory _setBaseURI) 
        ERC721(
            "CantoGraphs",
            "CGRPH"
        ){
            baseURI = _setBaseURI;
            _setDefaultRoyalty(royaltyReceiver, uint96(1000));
        }

    modifier onlyDistributor() {
        require(distributor == _msgSender(), "Cantograph: caller is not the distributor");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // minting should be called from the distributor contract which assigns an ID and gives it to the caller
    function mintFromDistributor(address to, uint256 id) external onlyDistributor {
        require(id<=MAX_ID && id != 0, "Cantograph: invalid ID");
        _mint(to, id);
    }

    ////////////////////////////////// Owner only functions //////////////////////////////////

    function updateRoyalties(address newRoyaltyReceiver, uint96 newNumerator) external onlyOwner {
        _setDefaultRoyalty(newRoyaltyReceiver, newNumerator);
    }

    function setDistributor(address newDistributor) external onlyOwner {
        distributor = newDistributor;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC2981) returns (bool) {
        return  interfaceId == type(IERC721Enumerable).interfaceId ||
                interfaceId == type(IERC2981).interfaceId ||
                super.supportsInterface(interfaceId);
    }
}
