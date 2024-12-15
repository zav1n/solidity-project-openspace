import { Component, createContext } from "react";
const theme = {
  light: {
    foreground: "#000000",
    background: "#eeeeee"
  },
  dark: {
    foreground: "#ffffff",
    background: "#222222"
  }
};

const ThemeContext = createContext({
  theme: theme.light,
  toggleTheme: () => {}
});

class App extends Component {
  constructor(){
    super()

    this.state = {
      theme: theme.light,
      toggeleTheme: this.toggleTheme
    }
  }

  toggleTheme = () => {
    this.setState({
      theme: this.state.theme === theme.light ? theme.dark : theme.light
    });
  };


  render() {
    return (
      <>
        <ThemeContext.Provider value={{ theme: this.state.theme, toggleTheme: this.toggleTheme }}>
          <A></A>
        </ThemeContext.Provider>
        {/* <button onClick={() => this.toggleTheme()}>toggleTheme</button> */}
      </>
    );
  }
}

// 1. 不能在模版里面打印this.context, 如果一定在模版打印, 要JSON.stringify
// 2. 不能直接在static 下一行console
// 3. this.context 只能在组件实例的生命周期方法中访问
class A extends Component {
  static contextType = ThemeContext;
  render() {
    console.log("contextType", this.context);
    return (
      <>
        <div>{JSON.stringify(this.context)}</div>
        <B></B>
      </>
    );
  }
}

// 4. 函数式组件需要使用ThemeContext.Consumer并且里面返回函数表达式{() => {}}
function B() {
  return (
    <ThemeContext.Consumer>
      {({ theme, toggleTheme }) => (
        <>
          {/* <div>{theme}</div> */}
          <button onClick={toggleTheme}>toggleTheme</button>
        </>
      )}
    </ThemeContext.Consumer>
  );
}

export default App;