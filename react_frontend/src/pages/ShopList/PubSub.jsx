import { Component } from "react";

class dataSource {
  constructor() {
    this.listener = [];
  }

  addListerner(cb) {
    this.listener.push(cb);
  }
  removeListerner(cb) {
    const index = this.listener.indexOf(cb)
    this.listener.splice(index, 1)
  };

  publish(data) {
    for (let i = 0; i < this.listener.length; i++) {
      const listener = this.listener[i];
      listener(data);
    }
  }
}

class App extends Component {

  constructor() {
    super()

    const data_source = new dataSource();
    
    const A_SUB = (data) => {
      console.log("A", data);
    }
    data_source.addListerner(A_SUB);
    data_source.addListerner((data) => {
      console.log("B", data);
    })

    data_source.removeListerner(A_SUB);
    
    data_source.publish("you'r component");
  }

  render() {
    return(<>console show Pub/Sub</>)
  }
}

export { App };

