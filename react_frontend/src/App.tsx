import React from "react";
import { Link } from "react-router-dom";
import AppRoutes from "../router/index";

const App = () => {
  return (
    <div style={{ display: "flex" }}>
      <div
        style={{ width: "200px", backgroundColor: "#f4f4f4", padding: "20px" }}
      >
        <ul>
          <li>
            <Link to="/">Home</Link>
          </li>
          <li>
            <Link to="/about">About</Link>
          </li>
        </ul>
      </div>
      <div style={{ padding: "20px", flexGrow: 1 }}>
        <AppRoutes />
      </div>
    </div>
  );
};

export default App;
