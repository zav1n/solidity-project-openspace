// Define IBank interface
interface IBank {
    event Deposit(address, uint256);
    event Withdraw(address, uint256);

    // function owner() external view returns (address);

    struct Account {
        address addr;
        uint256 balance;
    }

    function deposit() external payable;
    function withdraw() external;

    function getBalance(address) external returns(uint256);

    function getTop() external view returns(Account[] memory);
}