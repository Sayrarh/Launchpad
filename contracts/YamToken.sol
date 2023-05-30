// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YamToken is ERC20, Ownable {
    constructor() ERC20("YamToken", "YAM") {
        _mint(address(this), 9000000 * 10 ** decimals());
    }

    function mint(address _launchPadAddr, uint256 amount) public onlyOwner {
        _mint(_launchPadAddr, amount);
    }
}
