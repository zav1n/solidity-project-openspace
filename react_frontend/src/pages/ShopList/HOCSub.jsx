import { Component } from "react";


/**
 * 不要试图在HOC中修改组件原型
 * 保证是一个纯函数: 职责要单一
 * render函数不建议返回一个组件
 */
function withSubscript(WarpperComp, selectData) {

  return class extends Component {
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
}