import { createRef, Component, forwardRef } from "react";

const FancyButton = forwardRef((props, ref) => {
  return (
    <button ref={ref} className="FancyButton">
      {props.children}
    </button>
  );
})

class App extends Component {

  constructor() {
    super()

    this.FancyButtonRef = createRef();

  }

  componentDidMount() {
    console.log("FancyButtonRef", this.FancyButtonRef);
  }

  render() {
    return (
      <>
        <FancyButton ref={this.FancyButtonRef}>
          forwardRef
        </FancyButton>
      </>
    );
  }
}

export {
  App
}