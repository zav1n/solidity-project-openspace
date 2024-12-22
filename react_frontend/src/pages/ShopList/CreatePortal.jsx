import { Component, useState } from "react";
import { createPortal } from "react-dom";

class App extends Component {
  constructor(props) {
    super(props);

    this.rootDOM = document.querySelector('#root')
  }

  render() {
    return (
      <>
        <h1>123</h1>
        {createPortal(<h1>create a portal</h1>, this.rootDOM)}
      </>
    );
  }
}


function Dialog() {
  const [visibleDialog, setVisible] = useState(false)
  const rootDOM = document.querySelector('#root')
  return (
    <>
      <style>
        {`
          .modal {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background-color: #fff;
            padding: 20px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
            z-index: 1000;
          }

          .overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.5);
            z-index: 999;
          }
        `}
      </style>
      <button onClick={() => setVisible(true)}>打开弹窗</button>
      {visibleDialog &&
        createPortal(
          <>
            <div className="overlay"></div>
            <div className="modal">
              <div>这是一个模态对话框</div>
              <button onClick={() => setVisible(false)}>关闭</button>
            </div>
          </>,
          rootDOM
        )}
    </>
  );
}

const modalStyle = {
  position: "fixed",
  top: "50%",
  left: "50%",
  transform: "translate(-50%, -50%)",
  backgroundColor: "#fff",
  padding: "20px",
  boxShadow: "0 4px 8px rgba(0, 0, 0, 0.2)",
  zIndex: 1000
};

export { App, Dialog };