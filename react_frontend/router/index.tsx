import React from "react";
import { Route, Routes } from "react-router-dom";
import DemoPage from "../src/pages/DemoPage";
import Page from "../src/pages/Page";

const AppRoutes = () => {
  return (
    <Routes>
      <Route path="/" element={<Page />} />
      <Route path="/demoPage" element={<DemoPage />} />
    </Routes>
  );
};

export default AppRoutes;
