import { Component } from "react";

class dataSource {
  constructor() {
    this.commentData = [];
    this.listener = [];
  }

  addListerner(cb) {
    this.listener.push(cb);
  }
  removeListerner(cb) {
    const index = this.listener.indexOf(cb);
    this.listener.splice(index, 1);
  }

  publish(data) {
    this.commentData.push(data)
    for (let i = 0; i < this.listener.length; i++) {
      const listener = this.listener[i];
      listener(data);
    }
  }

  getComment() {
    return this.commentData;
  };
}

class App extends Component {
  constructor(props) {
    super(props);

    this.data_source = new dataSource();

    this.state = {
      inputValue: '',
      comments: this.data_source.getComment()
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
      comment: this.data_source.getComment()
    })
  };

  render() {
    return (
      <>
        <input
          type="text"
          value={this.state.inputValue}
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
        {this.state.comments.map(v => {
          return <div key={v}>{v}</div>
        })}
      </>
    );
  }
}

export { App, dataSource };

