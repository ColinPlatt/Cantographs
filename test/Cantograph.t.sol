// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Cantographs.sol";
import "src/Distributor.sol";

contract CantographsTest is Test {

    Cantographs public nft;
    Distributor public distributor;

    address public constant alice = address(0xA11ce);
    address public constant dep = address(0xad1);
    
    function setUp() public {
        vm.startPrank(dep);

            nft = new Cantographs("test");
            distributor = new Distributor(address(nft));
            nft.setDistributor(address(distributor));

        vm.stopPrank();
    }

    function testMint_Ten() public {

        vm.deal(alice, 10_000 ether);

        vm.startPrank(alice);

            distributor.mint{value: 125 ether*10}(10);

        vm.stopPrank();

        assertEq(nft.balanceOf(alice), 10);

    }

    function testMintUnderpriced() public {

        vm.deal(alice, 10_000 ether);

        vm.startPrank(alice);
        
            vm.expectRevert(bytes("Insufficient payment"));
            distributor.mint{value: 124 ether*10}(10);

        vm.stopPrank();

        assertEq(nft.balanceOf(alice), 0);

    }

    function testMintTooMany() public {

        vm.deal(alice, 10_000 ether);

        vm.startPrank(alice);
        
            vm.expectRevert(bytes("Max 10 mints"));
            distributor.mint{value: 125 ether*11}(11);

        vm.stopPrank();

        assertEq(nft.balanceOf(alice), 0);

        vm.startPrank(alice);
            
            distributor.mint{value: 125 ether*10}(10);
            assertEq(nft.balanceOf(alice), 10);

            vm.expectRevert(bytes("Max 10 per address"));
            distributor.mint{value: 125 ether*1}(1);
            assertEq(nft.balanceOf(alice), 10);

        vm.stopPrank();

    }

    function testMintOwner() public {

        vm.startPrank(dep);
        
            distributor.mint(11);

        vm.stopPrank();

        assertEq(nft.balanceOf(dep), 11);

    }

    function testCanMintAll() public {

        for(uint256 i = 0; i<100; ++i) {

            vm.deal(address(uint160(i+1)), 10_000 ether);

            vm.startPrank(address(uint160(i+1)));

                distributor.mint{value: 125 ether*10}(10);
                
            vm.stopPrank();

            assertEq(nft.balanceOf(address(uint160(i+1))), 10);

            for(uint256 j = 0; j<10; ++j) {
                assert(nft.tokenOfOwnerByIndex(address(uint160(i+1)),j)<1001);
                assert(nft.tokenOfOwnerByIndex(address(uint160(i+1)),j)>0);
            }
        }

        assertEq(nft.totalSupply(), 1000);

        vm.deal(alice, 10_000 ether);

        vm.startPrank(alice);
        
            vm.expectRevert(bytes("Mint closed"));
            distributor.mint{value: 125 ether*1}(1);

        vm.stopPrank();

        assertEq(nft.balanceOf(alice), 0);

    }

    function testSupportsInterface() public {

        assert(nft.supportsInterface(type(IERC721).interfaceId));
        assert(nft.supportsInterface(type(IERC721Metadata).interfaceId));
        assert(nft.supportsInterface(type(IERC721Enumerable).interfaceId));
        assert(nft.supportsInterface(0x01ffc9a7)); //165
        assert(nft.supportsInterface(type(IERC2981).interfaceId));

    }

    function testMintFromContract() public {

        vm.startPrank(dep);
        
            vm.expectRevert("Cantograph: caller is not the distributor");
            nft.mintFromDistributor(dep, 1);

        vm.stopPrank();

        assertEq(nft.balanceOf(dep), 0);

        vm.startPrank(alice);
        
            vm.expectRevert("Cantograph: caller is not the distributor");
            nft.mintFromDistributor(alice, 1);

        vm.stopPrank();

        assertEq(nft.balanceOf(alice), 0);


    }



}
