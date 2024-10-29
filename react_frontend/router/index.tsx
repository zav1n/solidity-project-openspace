import React from "react";
import { Route, Routes } from "react-router-dom";
import Home from "../src/pages/page1";
import About from "../src/pages/page";

const AppRoutes = () => {
  return (
    <Routes>
      <Route path="/" element={<Home />} />
      <Route path="/about" element={<About />} />
    </Routes>
  );
};

export default AppRoutes;
