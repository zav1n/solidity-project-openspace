// import React from "react";
import { Route, Routes } from "react-router-dom";
import Eth_getStorageAt from "../src/pages/Eth_getStorageAt";
import DepositWithPermit2 from "../src/pages/TokenBank/DepositWithPermit2";
import Flashboot from "../src/pages/flashboot";
import Keystore from "../src/pages/Keystore";
import Contract from "../src/pages/ReadContract/Contract";
import ShopList from "../src/pages/ShopList";

export const menu = [
  DepositWithPermit2,
  Eth_getStorageAt,
  Flashboot,
  Keystore,
  Contract,
  ShopList
];

const AppRoutes = () => {
  return (
    <Routes>
      {menu.map((Component, index) => (
        <Route
          key={Component.name}
          path={index === 0 ? "/" : `/${Component.name}`}
          element={<Component />}
        />
      ))}
    </Routes>
  );
};

export default AppRoutes;
