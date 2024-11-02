// import React from "react";
import { Route, Routes } from "react-router-dom";
import DemoPage from "../src/pages/DemoPage";
import DepositWithPermit2 from "../src/pages/TokenBank/DepositWithPermit2";

const AppRoutes = () => {
  return (
    <Routes>
      <Route path="/" element={<DepositWithPermit2 />} />
      <Route path="/demoPage" element={<DemoPage />} />
    </Routes>
  );
};

export default AppRoutes;
