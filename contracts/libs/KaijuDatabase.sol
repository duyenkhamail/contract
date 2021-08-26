import "../interfaces/IDatabase.sol";

import "./RoleDefine.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract KaijuDatabase is IDatabase, Initializable, AccessControlUpgradeable {
    mapping(uint256 => mapping(uint256 => uint256)) public mixingTable;

    function initialize(
        uint256[] memory _rows,
        uint256[] memory _columns,
        uint256[] memory _data
    ) public initializer {
        require(
            _rows.length == _columns.length,
            "INVALID ROWS OR COLUMN COUNT"
        );
        require(_rows.length == _data.length, "INVALID DATA COUNT");
        for (uint256 i = 0; i < _rows.length; i++) {
            mixingTable[_rows[i]][_columns[i]] = _data[i];
        }
    }

    function setMixingTable(
        uint256[] memory _rows,
        uint256[] memory _columns,
        uint256[] memory _data
    ) external onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE) {
        require(
            _rows.length == _columns.length,
            "INVALID ROWS OR COLUMN COUNT"
        );
        require(_rows.length == _data.length, "INVALID DATA COUNT");
        for (uint256 i = 0; i < _rows.length; i++) {
            mixingTable[_rows[i]][_columns[i]] = _data[i];
        }
    }

    function mergeEggs(uint256 _egg1, uint256 _egg2)
        external
        override
        view
        returns (uint256 _combinedEgg)
    {
        _combinedEgg = mixingTable[_egg1][_egg2];
        if (_combinedEgg == 0) {
            _combinedEgg = mixingTable[_egg2][_egg1];
        }
    }
}
