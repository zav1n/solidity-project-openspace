import { ethers } from "ethers";
import { useState } from "react";
import ViewJson from "react-json-view";

export default function Keystore() {
  // const wallet = new ethers.Wallet(privateKey);
  const [inputValue, setInputValue] = useState("");
  const [selectValue, setSelectValue] = useState("privateKey");
  const [pwd, setPwd] = useState("");
  const [kp, setKp] = useState("{}");

  const exxcute = async () => {
    try {
      if (selectValue === "privateKey") {
        const wallet = new ethers.Wallet(inputValue);
        const ks = await wallet.encrypt(pwd);
        console.log("ks", ks);
        setKp(ks);
      } else if (selectValue === "keystore") {
        const wallet = await ethers.Wallet.fromEncryptedJson(
          kp,
          pwd
        );
        console.warn(wallet.privateKey);
        setKp(`{ "privateKey": "${wallet.privateKey}" }`);
      }
    } catch (error) {
      alert(error)
    }
  }
  return (
    <>
      <div style={{ display: "flex" }}>
        <div style={{ display: "flex", width: "40%", flexWrap: "wrap" }}>
          <select
            style={{ width: "80%" }}
            id="privateKey"
            onChange={(e) => setSelectValue(e.target.value)}
          >
            <option value="privateKey">PrivateKey</option>
            <option value="keystore">Keystore</option>
          </select>
          <button style={{ width: "20%" }} onClick={exxcute}>
            exxcute
          </button>
          <input
            style={{ width: "100%" }}
            type="text"
            placeholder="password"
            onChange={(e) => setPwd(e.target.value)}
          />
          <textarea
            style={{ width: "100%" }}
            rows={37}
            onChange={(e) => setInputValue(e.target.value)}
          />
        </div>
        <ViewJson
          style={{ marginLeft: "30px" }}
          src={JSON.parse(kp)}
          displayObjectSize={false}
          displayDataTypes={false}
          enableClipboard={true}
        ></ViewJson>
      </div>
    </>
  );
}
