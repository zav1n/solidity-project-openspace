// import React from "react";
import { Route, Routes } from "react-router-dom";
import Eth_getStorageAt from "../src/pages/Eth_getStorageAt";
import DepositWithPermit2 from "../src/pages/TokenBank/DepositWithPermit2";
import Flashboot from "../src/pages/flashboot";
import Keystore from "../src/pages/Keystore";
import Contract from "../src/pages/ReadContract/Contract";

export const menu = [
  DepositWithPermit2,
  Eth_getStorageAt,
  Flashboot,
  Keystore,
  Contract
];

const AppRoutes = () => {
  return (
    <Routes>
      {menu.map((Component, index) => (
        <Route
          path={index === 0 ? "/" : `/${Component.name}`}
          element={<Component />}
        />
      ))}
    </Routes>
  );
};

export default AppRoutes;
