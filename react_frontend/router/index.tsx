// import React from "react";
import { Route, Routes } from "react-router-dom";
import Eth_getStorageAt from "../src/pages/Eth_getStorageAt";
import DepositWithPermit2 from "../src/pages/TokenBank/DepositWithPermit2";

const AppRoutes = () => {
  return (
    <Routes>
      <Route path="/" element={<DepositWithPermit2 />} />
      <Route path="/Eth_getStorageAt" element={<Eth_getStorageAt />} />
    </Routes>
  );
};

export default AppRoutes;
