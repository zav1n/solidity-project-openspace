import { BrowserRouter, Route, RouterContext } from "./router/index.jsx";
function Home() {
  return <h1>Home</h1>;
}

function About() {
  return <h1>About</h1>;
}

function TestPage() {
  return <h1>TestPage</h1>;
}
function App() {

  return (
    <BrowserRouter>
      <RouterContext.Consumer>
        {(router) => (
          <>
            <button onClick={() => router.goPath("/")}>Home</button>
            <button onClick={() => router.goPath("/about")}>About</button>
            <button onClick={() => router.goPath("/testPage")}>testPage</button>
            <Route path="/" component={Home} />
            <Route path="/about" component={About} />
            <Route path="/testPage" component={TestPage} />
          </>
        )}
      </RouterContext.Consumer>
    </BrowserRouter>
  );
}

export default App
