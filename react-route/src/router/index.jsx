import { useState, useEffect } from "react";
import { createContext } from "react";


const RouterContext = createContext()

function BrowserRouter(props) {
  const [path, setPath] = useState(() => {
    const { pathname } = window.location
    return pathname || "/";
  })

  const handlePopstate = (e) => {
    setPath(e.state.path);
  };

  useEffect(() => {
    window.addEventListener('popstate', handlePopstate)

    return () => {
      window.removeEventListener("popstate", handlePopstate);
    };
  }, [])
  
  

  const goPath = (path) => {
    setPath(path)
    window.history.pushState({path}, '', path)
  }

  const routerData = {
    path,
    goPath
  }
  return (
    <RouterContext.Provider value={routerData}>
      {props.children}
    </RouterContext.Provider>
  );
}

function Route(props) {
  const { path, component: Component } = props;
  
  return (
    <RouterContext.Consumer>
      {(router) => (path === router.path ? <Component /> : null)}
    </RouterContext.Consumer>
  );
}


export {
  BrowserRouter,
  RouterContext,
  Route
}