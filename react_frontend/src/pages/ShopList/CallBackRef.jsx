import { Component } from "react";

class Parent extends Component{
  render() {
    return <>{ this.props.children }</>;
  }
}

class Child extends Component{
  render() {
    return(<div ref={this.props.inputRef}></div>)
  }
}





class CallBackRef extends Component{
  componentDidMount(){
    console.log("this.inputElement", this.inputElement);
  }
  render(){
    return(
    <Parent>
      <Child inputRef={el => this.inputElement = el}></Child>
    </Parent>
    )
  }
}

export default CallBackRef;