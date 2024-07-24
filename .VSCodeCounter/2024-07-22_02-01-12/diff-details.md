# Diff Details

Date : 2024-07-22 02:01:12

Directory /home/gas_limit/leveraged-mm/test

Total : 40 files,  -1476 codes, -2058 comments, -569 blanks, all -4103 lines

[Summary](results.md) / [Details](details.md) / [Diff Summary](diff.md) / Diff Details

## Files
| filename | language | code | comment | blank | total |
| :--- | :--- | ---: | ---: | ---: | ---: |
| [src/CentralRegistry.sol](/src/CentralRegistry.sol) | solidity | -24 | -19 | -12 | -55 |
| [src/Factory.sol](/src/Factory.sol) | solidity | -28 | -17 | -14 | -59 |
| [src/LeveragedNFT.sol](/src/LeveragedNFT.sol) | solidity | -20 | -14 | -10 | -44 |
| [src/Master.sol](/src/Master.sol) | solidity | -95 | -40 | -35 | -170 |
| [src/Proxy.sol](/src/Proxy.sol) | solidity | -28 | -14 | -12 | -54 |
| [src/implementations/Long_Base_Odos_Zerolend.sol](/src/implementations/Long_Base_Odos_Zerolend.sol) | solidity | -243 | -30 | -117 | -390 |
| [src/implementations/Long_Quote_Odos_Zerolend.sol](/src/implementations/Long_Quote_Odos_Zerolend.sol) | solidity | -251 | -95 | -103 | -449 |
| [src/implementations/Shared_Storage.sol](/src/implementations/Shared_Storage.sol) | solidity | -8 | -9 | -6 | -23 |
| [src/implementations/Short_Base_Odos_Zerolend.sol](/src/implementations/Short_Base_Odos_Zerolend.sol) | solidity | -5 | -2 | -1 | -8 |
| [src/implementations/Short_Quote_Odos_Zerolend.sol](/src/implementations/Short_Quote_Odos_Zerolend.sol) | solidity | -5 | -2 | -1 | -8 |
| [src/interfaces/ICentralRegistry.sol](/src/interfaces/ICentralRegistry.sol) | solidity | -20 | -1 | -9 | -30 |
| [src/interfaces/IERC721A.sol](/src/interfaces/IERC721A.sol) | solidity | -58 | -205 | -44 | -307 |
| [src/interfaces/IERC721Receiver.sol](/src/interfaces/IERC721Receiver.sol) | solidity | -9 | -17 | -2 | -28 |
| [src/interfaces/IFactory.sol](/src/interfaces/IFactory.sol) | solidity | -4 | -1 | -1 | -6 |
| [src/interfaces/ILeverageNFT.sol](/src/interfaces/ILeverageNFT.sol) | solidity | -5 | -1 | -4 | -10 |
| [src/interfaces/IMaster.sol](/src/interfaces/IMaster.sol) | solidity | -25 | -1 | -9 | -35 |
| [src/interfaces/IProxy.sol](/src/interfaces/IProxy.sol) | solidity | -20 | -1 | -6 | -27 |
| [src/interfaces/external/odos/IOdosRouterV2.sol](/src/interfaces/external/odos/IOdosRouterV2.sol) | solidity | -36 | -1 | -6 | -43 |
| [src/interfaces/external/zerolend/DataTypes.sol](/src/interfaces/external/zerolend/DataTypes.sol) | solidity | -200 | -43 | -22 | -265 |
| [src/interfaces/external/zerolend/IFlashLoanSimpleReceiver.sol](/src/interfaces/external/zerolend/IFlashLoanSimpleReceiver.sol) | solidity | -14 | -18 | -4 | -36 |
| [src/interfaces/external/zerolend/IPool.sol](/src/interfaces/external/zerolend/IPool.sol) | solidity | -214 | -462 | -61 | -737 |
| [src/interfaces/external/zerolend/IPoolAddressProvider.sol](/src/interfaces/external/zerolend/IPoolAddressProvider.sol) | solidity | -42 | -155 | -30 | -227 |
| [src/libraries/ERC721A/ERC721A.sol](/src/libraries/ERC721A/ERC721A.sol) | solidity | -539 | -618 | -157 | -1,314 |
| [src/libraries/openzeppelin/interfaces/IERC1363.sol](/src/libraries/openzeppelin/interfaces/IERC1363.sol) | solidity | -11 | -66 | -9 | -86 |
| [src/libraries/openzeppelin/interfaces/IERC165.sol](/src/libraries/openzeppelin/interfaces/IERC165.sol) | solidity | -2 | -2 | -2 | -6 |
| [src/libraries/openzeppelin/interfaces/IERC20.sol](/src/libraries/openzeppelin/interfaces/IERC20.sol) | solidity | -12 | -59 | -10 | -81 |
| [src/libraries/openzeppelin/proxy/Proxy.sol](/src/libraries/openzeppelin/proxy/Proxy.sol) | solidity | -24 | -37 | -8 | -69 |
| [src/libraries/openzeppelin/token/SafeERC20.sol](/src/libraries/openzeppelin/token/SafeERC20.sol) | solidity | -89 | -80 | -16 | -185 |
| [src/libraries/openzeppelin/utils/Address.sol](/src/libraries/openzeppelin/utils/Address.sol) | solidity | -63 | -76 | -12 | -151 |
| [src/libraries/openzeppelin/utils/Errors.sol](/src/libraries/openzeppelin/utils/Errors.sol) | solidity | -6 | -16 | -4 | -26 |
| [src/libraries/openzeppelin/utils/introspection/IERC165.sol](/src/libraries/openzeppelin/utils/introspection/IERC165.sol) | solidity | -4 | -19 | -2 | -25 |
| [test/Mocks/FlashLoanMock.sol](/test/Mocks/FlashLoanMock.sol) | solidity | 25 | 1 | 13 | 39 |
| [test/README.md](/test/README.md) | Markdown | 5 | 0 | 4 | 9 |
| [test/strategy/Long_Base_Odos_ZeroLend/Long_Base_Odos_ZeroLend_Test.t.sol](/test/strategy/Long_Base_Odos_ZeroLend/Long_Base_Odos_ZeroLend_Test.t.sol) | solidity | 70 | 32 | 47 | 149 |
| [test/strategy/Long_Base_Odos_ZeroLend/OdosAdd.js](/test/strategy/Long_Base_Odos_ZeroLend/OdosAdd.js) | JavaScript | 85 | 5 | 8 | 98 |
| [test/strategy/Long_Base_Odos_ZeroLend/OdosRemove.js](/test/strategy/Long_Base_Odos_ZeroLend/OdosRemove.js) | JavaScript | 85 | 6 | 8 | 99 |
| [test/strategy/Long_Quote_Odos_ZeroLend/OdosAdd.js](/test/strategy/Long_Quote_Odos_ZeroLend/OdosAdd.js) | JavaScript | 85 | 5 | 8 | 98 |
| [test/strategy/Long_Quote_Odos_ZeroLend/OdosClose.js](/test/strategy/Long_Quote_Odos_ZeroLend/OdosClose.js) | JavaScript | 85 | 5 | 8 | 98 |
| [test/strategy/Long_Quote_Odos_ZeroLend/OdosRemove.js](/test/strategy/Long_Quote_Odos_ZeroLend/OdosRemove.js) | JavaScript | 85 | 5 | 8 | 98 |
| [test/strategy/Long_Quote_Odos_ZeroLend/Using_Proxy_Long_Quote_Odos_ZeroLend_Test.t.sol](/test/strategy/Long_Quote_Odos_ZeroLend/Using_Proxy_Long_Quote_Odos_ZeroLend_Test.t.sol) | solidity | 103 | 4 | 56 | 163 |

[Summary](results.md) / [Details](details.md) / [Diff Summary](diff.md) / Diff Details