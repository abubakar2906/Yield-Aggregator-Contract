// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract erc4626Logic {
    address public owner;
    address public strategy;
    mapping(address => uint256) public shares;  // Track each user's balance
    uint256 public totalBalance;
    uint256 public totalShares;
    address public usdcToken;

    function deposit(uint256 amount) payable external {
        // Total usdc increases
        // total shares increases (new mints)
        // new depositer gets shares
        // price per share stays same
        // existing holders share counts same
        // existing holders usdc value stays same
        // shares = (amount * totalshares) / totalBalance
        uint256 sharesToMint;
        if(totalShares == 0){
            // first depositer case
            sharesToMint = amount;
        } else{
            // regular case - use formula from scenario
            sharesToMint = (amount * totalShares) / totalBalance;
        }
        // you need a reference to the usdc token contract
        // let's assume you have: address public usdcToken
        // Update state
        totalBalance = totalBalance + amount;
        totalShares = totalShares + sharesToMint;
        shares[msg.sender] = shares[msg.sender] + sharesToMint;


        IERC20(usdcToken).transferFrom(
            msg.sender, // user sending usdc
            address(this), // contract receiving usdc
            amount // how much usdc
        );
    }
    // Helper function to get the usdc balance
    function balanceOf(address account) public view returns(uint256) {  // ✅ Renamed parameter
    if(totalShares == 0) return 0;
    return (shares[account] * totalBalance) / totalShares;  // Updated to use `account`
}

   

    function withdraw(uint256 amount) external{
        // total usdc decreases
        // total shares decreases
        // price per share stay same
        // other holders share counts stay same
        // other holders usdc value stays the same

        //calculate how many shares to burn
        uint256 sharesToBurn = (amount * totalShares) / totalBalance;

        // check if user has enough
        require(shares[msg.sender] >= sharesToBurn,"Not enough shares");

        // update state variables first(Before transfer)
        totalBalance -= amount;
        totalShares -= sharesToBurn;
        shares[msg.sender] -= sharesToBurn;

        // transfer usdc from contract to user
        IERC20(usdcToken).transfer(msg.sender, amount);
    }

    function setStrategy(address _strategy) external {
        // owner sets which strategy to use
    }

    function deployToStrategy(uint256 amount) external{
        // keeper moves idle usdc into strategy
    }

    function harvestFromStrategy() external{
        // keeper collects profit from strategy
        // updates vaults totalBalance
    }

    function totalAssets() public view returns(uint256){
        // Override this
        // Return idle USDC + strategy balance
    }


    


    

    

}

contract MockStrategy{
    address public vault; // who can deposit/withdraw
    IERC20 public asset;   // USDC
    uint256 public totalDeposited; // how much vault gave us
    uint256 public APR;  // Simulated yield(500 = 5%)
    uint256 public lastUpdate; // When we last accrued interest

    constructor(address _vault, address _asset, uint256 _aprBps){
        vault = _vault;
        asset = IERC20(_asset);  // ✅ Explicitly convert address → IERC20
        APR = _aprBps;
    }

    // vault calls this to give us USDC bacl
    function deposit(uint256 amount) external returns(uint256) {
        // check only vault can call
        require(msg.sender == vault,"only vault");

        // receive USDC from vault
        asset.transferFrom(vault, address(this), amount);

        // track how much we received
        totalDeposited += amount;

        // update timestamp
        lastUpdate = block.timestamp;

        // Return amount received
        return amount;                                       


    }

    // vault calls this to take USDC back
    function withdraw(uint256 amount) external returns(uint256) {
        // check only vault can call
        require(msg.sender == vault, "only");

        // send usdc to vault
        asset.transfer(vault, amount);

        // decrease tracked amount
        totalDeposited -= amount;

        // update timestamp
        lastUpdate = block.timestamp;

        // return amount withdrawn
        return amount;

    }

    // Returns total value including fake profit
    function totalAssets() external view returns (uint256) {
        // calculate: totaldeposited + fake interest
        // formula for interest: principal * (APR / 1000) *(timeElapsed / 1 year)

        // calculate time elapsed
        uint256 timeElapsed = block.timestamp - lastUpdate;

        // calculate fake interest using the formula
        uint256 interest = (totalDeposited * APR * timeElapsed) /  (10000 * 365 days);

        // return totaldep + interest
        uint256 totalValue = totalDeposited + interest;

        return totalValue;
        
    }   

    // Returns the profit
    function harvest() external returns (int256) {
        // Only vault can call it
        require(msg.sender == vault, "Only vault");

        // Calculate time elapsed
        uint256 timeElapsed = block.timestamp - lastUpdate;

        // interest earned
        uint256 interest = (totalDeposited * APR * timeElapsed) /  (10000 * 365 days);

        // add interest to totaldep(make profit "real")
        totalDeposited += interest;

        // reset the clock
        lastUpdate =  block.timestamp;

        // return profit as int256
        return int256(interest);


        
    }
    
}