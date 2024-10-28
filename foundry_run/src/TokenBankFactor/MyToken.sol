import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20 {
    // 每次发行的数量
    uint256 public perMint;

    constructor(string memory name, uint256 totalSupply) ERC20(name, name) {
        _mint(msg.sender, totalSupply);
        perMint = 0; // 初始化为0，需在合约外部设置
    }

    // 设置每次发行的数量（只有合约拥有者可以调用）
    function setPerMint(uint256 _perMint) external {
        perMint = _perMint;
    }

    // 发行新的代币
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}