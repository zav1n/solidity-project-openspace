import React from "react";
import { Link } from "react-router-dom";
import AppRoutes, { menu } from "../router/index";
import AppKitProvider from "./AppKit/index";
import HeaderWallet from "./pages/HeaderWallet";

const App = () => {
  return (
    <AppKitProvider>
      <div style={{ display: "flex", height: "100vh" }}>
        <div
          style={{
            width: "200px",
            backgroundColor: "#f4f4f4",
            padding: "20px"
          }}
        >
          <ul>
            {menu.map((Component, index) => {
              return (
                <li key={Component.name}>
                  <Link to={index === 0 ? "/" : `/${Component.name}`}>
                    {Component.name}
                  </Link>
                </li>
              );
            })}
          </ul>
        </div>
        <div style={{ width: "100%", paddingLeft: "10px" }}>
          <HeaderWallet />
          <div>
            <AppRoutes />
          </div>
        </div>
      </div>
    </AppKitProvider>
  );
};

export default App;
