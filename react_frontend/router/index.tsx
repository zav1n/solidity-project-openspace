// import React from "react";
import { Route, Routes } from "react-router-dom";
import DemoPage from "../src/pages/DemoPage";
import Permit2 from "../src/pages/Permit2";

const AppRoutes = () => {
  return (
    <Routes>
      <Route path="/" element={<Permit2 />} />
      <Route path="/demoPage" element={<DemoPage />} />
    </Routes>
  );
};

export default AppRoutes;
