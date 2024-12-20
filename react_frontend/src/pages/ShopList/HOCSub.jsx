import { Component } from "react";

function withSubscript(WarpperComp, selectData) {

  class App extends Component {
    constructor(props) {
      super(props);
  
      this.state = {
        data: selectData(DataSource, props)
      };
    }
  
    // 挂载时, 添加订阅
    componentDidMount() {
      this.data_source.addListerner(this.handleChange);
    }
  
    // 销毁时, 清除订阅
    componentWillUnmount() {
      this.data_source.removeListerner(this.handleChange);
    }
  
    handleChange = () => {
      this.setState({
        data: selectData(DataSource, props)
      });
    };

    render(){
      return <WarpperComp data={this.state.data} {...props}></WarpperComp>
    }
  }

  return App;
}