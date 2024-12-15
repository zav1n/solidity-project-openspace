import { Component } from "react";

class ErrorBoundary extends Component {
  constructor(props) {
    super(props)

    this.state = {
      hasError: false
    }
  }


  static getDerivedStateFromError(error) {
    return { hasError: true }
  }

  componentDidCatch(error, errorInfo) {
    console.log(error, errorInfo);
  }

  render() {
    if(this.state.hasError){
      return (
        <>
          <div>发生错误</div>
        </>
      );
    }

    return this.props.children
  }
}

class A extends Component {
  render() {
    throw '报错'
    return(<div>渲染A组件</div>)
  }
}

class ExampleError extends Component {
  render() {
    return(
      <ErrorBoundary>
        <A></A>
      </ErrorBoundary>
    )
  }
}

export default ExampleError;