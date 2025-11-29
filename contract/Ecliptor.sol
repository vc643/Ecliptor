// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Ecliptor
 * @dev Privacy-oriented ERC20 token with "Eclipse" stealth mode
 * Users can temporarily "eclipse" (hide) their tokens, making balance appear as zero on-chain
 * Eclipsed tokens can be "uneclipsed" later by the owner
 */
contract Ecliptor is ERC20, ERC20Burnable, Ownable {
    
    mapping(address => uint256) private _eclipsedBalance;
    mapping(address => bool) public isEclipsed;

    event Eclipsed(address indexed user, uint256 amount);
    event Uneclipsed(address indexed user, uint256 amount);
    event StealthTransfer(address indexed from, address indexed to, uint256 amount);

    constructor() ERC20("Ecliptor", "ECLP") Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000 * 10**decimals()); // 1M initial supply
    }

    /**
     * @dev Core Function 1: Eclipse your tokens (hide balance from public view)
     */
    function eclipse(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        _burn(msg.sender, amount);
        _eclipsedBalance[msg.sender] += amount;
        isEclipsed[msg.sender] = true;

        emit Eclipsed(msg.sender, amount);
    }

    /**
     * @dev Core Function 2: Uneclipse tokens (restore hidden tokens)
     */
    function uneclipse(uint256 amount) external {
        require(_eclipsedBalance[msg.sender] >= amount, "Not enough eclipsed tokens");
        
        _eclipsedBalance[msg.sender] -= amount;
        _mint(msg.sender, amount);

        if (_eclipsedBalance[msg.sender] == 0) {
            isEclipsed[msg.sender] = false;
        }

        emit Uneclipsed(msg.sender, amount);
    }

    /**
     * @dev Core Function 3: Stealth Transfer (transfer while in eclipsed state)
     * Only works if sender has eclipsed tokens and is currently eclipsed
     */
    function stealthTransfer(address to, uint256 amount) external {
        require(isEclipsed[msg.sender], "Must be in eclipse mode");
        require(_eclipsedBalance[msg.sender] >= amount, "Insufficient eclipsed balance");

        _eclipsedBalance[msg.sender] -= amount;
        _eclipsedBalance[to] += amount;

        if (_eclipsedBalance[msg.sender] == 0) {
            isEclipsed[msg.sender] = false;
        }
        isEclipsed[to] = true;

        emit StealthTransfer(msg.sender, to, amount);
    }

    // Override balanceOf to show 0 when user is eclipsed
    function balanceOf(address account) public view override returns (uint256) {
        if (isEclipsed[account]) {
            return 0;
        }
        return super.balanceOf(account);
    }

    // View function to check real total balance including eclipsed tokens
    function totalBalanceOf(address account) external view returns (uint256) {
        return super.balanceOf(account) + _eclipsedBalance[account];
    }

    // View eclipsed balance
    function eclipsedBalanceOf(address account) external view returns (uint256) {
        return _eclipsedBalance[account];
    }
}
