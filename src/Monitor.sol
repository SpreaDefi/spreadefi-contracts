// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/openzeppelin/token/SafeERC20.sol";
import "./interfaces/ICentralRegistry.sol";
import "./interfaces/IMaster.sol";
import "./interfaces/IProxy.sol";
import "src/interfaces/external/zerolend/IPoolAddressProvider.sol";
import "src/interfaces/external/zerolend/IPool.sol";
import "./interfaces/ILeverageNFT.sol";
import "./interfaces/IERC721A.sol";
import "./LeveragedNFT.sol";
import "./interfaces/IFactory.sol";
import {DataTypes} from "src/interfaces/external/zerolend/DataTypes.sol";

contract Monitor {

    ICentralRegistry public centralRegistry;

    constructor(address _centralRegistry) {
        centralRegistry = ICentralRegistry(_centralRegistry);
    }

    function getCollateralAmount(uint256 _tokenId) public view returns (address, uint256) {
        address leveragedNFT = centralRegistry.core("LEVERAGE_NFT");

        ILeverageNFT nft = ILeverageNFT(leveragedNFT);

        address proxyAddress = nft.tokenIdToProxy(_tokenId);

        IProxy proxy = IProxy(proxyAddress);

        address marginAddress;

        if(proxy.MARGIN_TYPE() == 0) {
            marginAddress = proxy.QUOTE_TOKEN();
        } else {
            marginAddress = proxy.BASE_TOKEN();
        }

        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");

        IPool pool = IPool(poolAddress);

        DataTypes.ReserveData memory assetData = pool.getReserveData(marginAddress);

        address aTokenAddress = assetData.aTokenAddress;

        uint256 aTokenBalance = IERC20(aTokenAddress).balanceOf(proxyAddress);

        return(marginAddress, aTokenBalance);

    }

    function getLoanAmount(uint256 _tokenId) public view returns (address, uint256) {
        address leveragedNFT = centralRegistry.core("LEVERAGE_NFT");

        ILeverageNFT nft = ILeverageNFT(leveragedNFT);

        address proxyAddress = nft.tokenIdToProxy(_tokenId);

        IProxy proxy = IProxy(proxyAddress);

        address loanTokenAddress;

        if(proxy.MARGIN_TYPE() == 0) {
            loanTokenAddress = proxy.BASE_TOKEN();
        } else {
            loanTokenAddress = proxy.QUOTE_TOKEN();
        }

        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");

        IPool pool = IPool(poolAddress);

        DataTypes.ReserveData memory assetData = pool.getReserveData(loanTokenAddress);

        address variableDebtTokenAddress = assetData.variableDebtTokenAddress;

        uint256 variableDebtTokenBalance = IERC20(variableDebtTokenAddress).balanceOf(proxyAddress);

        return(loanTokenAddress, variableDebtTokenBalance);


    }



}