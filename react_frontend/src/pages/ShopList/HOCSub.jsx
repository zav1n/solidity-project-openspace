import { Component, createRef, forwardRef } from "react";
import hoistNonReactStatics from "hoist-non-react-statics";
import { dataSource } from "./PubSubV2";

/**
 * 不要试图在HOC中修改组件原型
 * 保证是一个纯函数: 职责要单一
 * render函数不建议返回一个组件
 */

const mockData = null;
const DataSource = new dataSource();
function withSubscript(WarpperComp, selectData) {
  class App extends Component {
    constructor(props) {
      super(props);
      this.state = {
        data: selectData(mockData, props)
      };
    }

    // 挂载时, 添加订阅
    componentDidMount() {
      DataSource.addListerner(this.handleChange);
    }

    // 销毁时, 清除订阅
    componentWillUnmount() {
      DataSource.removeListerner(this.handleChange);
    }

    handleChange = () => {
      this.setState({
        data: selectData(mockData, props)
      });
    };

    render() {
      const { forwardRef, ...rest } = this.props
      console.warn("App this.props", this.props);
      console.warn("forwardRef", forwardRef);
      return (
        <WarpperComp
          ref={forwardRef}
          data={this.state.data}
          {...rest}
        ></WarpperComp>
      );
    }
  }

  hoistNonReactStatics(App, WarpperComp);

  /**
   * 1. 如果需要用到ref,  需要使用到forward
   * 
   * 2. 将不能使用匿名函数,
   * 
   * 3. hoc里面需要ref转发
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

  componentDidMount() {
    console.warn(this.ref)
  }

  render() {
    return (
      <>
        <div>TestComp</div>
      </>
    );
  }
}


const TestHOC = withSubscript(TestComp, (data) => data);


class TestRef extends Component {
  constructor() {
    super()
    this.testRef = createRef()
  }

  componentDidMount() {
    console.warn(this.testRef)
  }

  render() {
    return (
      <>
        <TestHOC ref={this.testRef} />
      </>
    );
  }
}

export { withSubscript, TestHOC, TestRef };

/**
 * 在高阶函数中, 调用原本组件的静态方法时, 需要在高阶函数里面加hoist-non-react-statics依赖
 */
// TestHOC.getNage();