import { Component, forwardRef, createRef, Fragment } from "react";

function LogProps(Component) {
  class LogPropsComponent extends Component {
    constructor() {
      super();
    }

    render() {
      const { forwardedRef, ...rest } = this.props;
      return <Component ref={forwardedRef} {...rest}></Component>;
    }
  }

  return forwardRef((props, ref) => {
    return (
      <LogPropsComponent {...props} forwardedRef={ref}></LogPropsComponent>
    );
  });
}

class TestComponent extends Component {
  constructor() {
    super()
  }

  render() {
    return <div>this test component</div>
  }
}

var Child = LogProps(TestComponent);


class App extends Component {
  constructor(){
    super()

    this.childRef = createRef();

  }

  componentDidMount(){
    console.log("this.childRef", this.childRef);
  }
  render(){
    return (
      <Fragment>
        <Child ref={this.childRef}></Child>
      </Fragment>
    );
  }
}

export {
  App
}