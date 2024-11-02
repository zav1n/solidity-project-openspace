import React from "react";
import { Link } from "react-router-dom";
import AppRoutes from "../router/index";
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
            <li>
              <Link to="/">DepositWithPermit2</Link>
            </li>
            <li>
              <Link to="/demoPage">DemoPage</Link>
            </li>
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
