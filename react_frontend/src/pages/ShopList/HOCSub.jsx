import { Component, forwardRef } from "react";
import hoistNonReactStatics from "hoist-non-react-statics";

/**
 * 不要试图在HOC中修改组件原型
 * 保证是一个纯函数: 职责要单一
 * render函数不建议返回一个组件
 */
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

    render() {
      return <WarpperComp data={this.state.data} {...props}></WarpperComp>;
    }
  }

  hoistNonReactStatics(App, WarpperComp);

  /**
   * 如果需要用到ref,  需要使用到forward
   * 
   * 将不能使用匿名函数,
   */
  return forwardRef((props, ref) => {
    return <App {...props} forwardRef={ref} />;
  });
}

class TestComp extends Component {
  constructor() {
    super()
  }

    static getNage = () => {
      console.warn("Mike")
    }

  render() {

  }
}


const comp = withSubscript(TestComp);

/**
 * 在高阶函数中, 调用原本组件的静态方法时, 需要在高阶函数里面加hoist-non-react-statics依赖
 */
comp.getNage()