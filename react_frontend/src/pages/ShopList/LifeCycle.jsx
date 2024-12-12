import { Component } from "react";

class ABI extends Component {
  constructor(props) {
    super(props);

    this.state = {
      abi: null
    };
  }

  // componentDidMount(props) {
  //   this.setState({
  //     abi: this.props.abi
  //   });
  //   console.log("componentDidMount", this.props, this);
  // }

  static getDerivedStateFromProps(nextProps, prevState) {
    // 可根据需要更新状态
    return {
      abi: nextProps.abi
    };
  }

  componentDidUpdate(preProps, preState) {
    console.log("componentDidUpdate", preProps);
  }

  shouldComponentUpdate() {
    console.log("shouldComponentUpdate");
    return true;
  }

  render() {
    return (
      <>
        <div>{this.state.abi}</div>
      </>
    );
  }
}

export default function ReadAbi(props) {
  // console.log("props", props);
  return (
    <>
      <ABI {...props}/>
    </>
  );
}
