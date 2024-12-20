import { Component } from "react";

class DataSource extends Component {
  constructor() {
    super()
    
    this.blobArr = []
    this.listerner = []

    this.state = {
      inputValue: null
    }
  }

  addListerner(cb) {
    this.listerner.push(cb)
  };

  removeListerner(cb) {
    const index = this.listerner.indexOf(cb)
    this.listerner.splice(index, 1)
  }

  publish(data) {
    console.warn(data);
    this.blobArr.push(JSON.parse(data));
    for (let i = 0; i < this.listerner.length; i++) {
      const listerner = this.listerner[i];
      listerner(data);
    }
  }

  getBlobPost(id) {
    console.warn(this.blobArr, id);
    const result = this.blobArr.find(item => item.id ===  id);
    console.warn("getBlobPost", result);
    return result;
  }
}


class BlobPost extends Component {
  constructor(props) {
    super(props);

    this.data_source = new DataSource();

    this.state = {
      blobPost: this.data_source.getBlobPost(props.id)
    };
  }

  componentDidMount() {
    this.data_source.addListerner(this.handleChange);
  }

  componentWillUnmount() {
    this.data_source.removeListerner(this.handleChange);
  }

  handleChange = () => {
    this.setState({
      blobPost: this.data_source.getBlobPost(this.props.id)
    })
  };

  render(){
    return (
      <>
        <input
          type="text"
          onChange={(e) =>
            this.setState({
              inputValue: e.target.value
            })
          }
        />
        <button
          onClick={() => {
            this.data_source.publish(this.state.inputValue);
          }}
        >
          publish
        </button>
        <div>{JSON.stringify(this.state.blobPost)}</div>
        <div>{this.props.id}</div>
      </>
    );
  }
}

class App extends Component {
  constructor() {
    super()

    this.state  = {
      id: null
    }
  }

  render() {
    return (
      <>
        <BlobPost id={this.state.id}></BlobPost>
        <input
          type="text"
          placeholder="props id"
          onChange={(e) =>
            this.setState({
              id: e.target.value
            })
          }
        />
      </>
    );
  }
}

export { App };