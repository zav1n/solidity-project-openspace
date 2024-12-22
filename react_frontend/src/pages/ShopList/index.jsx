import React from "react";
import LifeCycle from "./LifeCycle";
import Context from "./Context"
import ExampleError from "./ErrorBoundary";
import CallBackRef from "./CallBackRef";
import { App as ForwardRef } from "./ForwardRef";
import { App as FnforwardRef } from "./FnforwardRef";
import { App as PubSub } from "./PubSub";
import { App as PubSubV2 } from "./PubSubV2";
import { App as BlobPost } from "./BlobPost";
import { TestHOC, TestRef } from "./HOCSub";
class SearchBar extends React.Component {
  constructor(props) {
    super(props)
  }
  render() {
    
    return (
      <>
        <input 
          type="text" 
          value={this.props.filterText}
          onChange={(e) => this.props.handleFilter(e.target.value)}
        />
        <span>
          <input
            type="checkbox"
            value={this.props.isStock}
            onChange={(e)=> this.props.handleCheckStock(e.target.checked)}
          />
          stock
        </span>
      </>
    );
  }
}

class List extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    let listRow = [];
    let lastcategory = null;
    const { data, filterText, isStock } = this.props;

    data.forEach((item) => {
      if (item.name.indexOf(filterText) === -1) {
        return;
      }

      if (isStock && !item.stocked) {
        return
      }
        if (item.category !== lastcategory) {
          lastcategory = item.category;
          listRow.push(<ProductCategory key={item.category} category={item.category} />);
        }
        listRow.push(<ProductRow key={item.name} {...item} />);
    });
    return (
      <>
        <table>
          <thead>
            <tr>
              <th>name</th>
              <th>price</th>
            </tr>
          </thead>
          <tbody>{listRow}</tbody>
        </table>
      </>
    );
  }
}

// 种类
function ProductCategory(props) {
  return (
    <tr>
      <th colSpan={2}>{props.category}</th>
    </tr>
  );
}

// 列表
function ProductRow(props) {
  return (
    <tr>
      <th style={{ color: props.stocked ? "black" : "red" }}>{props.name}</th>
      <th>{props.price}</th>
    </tr>
  );
}

const data = [
  {
    category: "Sporting Goods",
    price: "$49.99",
    stocked: true,
    name: "Football"
  },
  {
    category: "Sporting Goods",
    price: "$9.99",
    stocked: true,
    name: "Baseball"
  },
  {
    category: "Sporting Goods",
    price: "$29.99",
    stocked: false,
    name: "Basketball"
  },
  {
    category: "Electronics",
    price: "$99.99",
    stocked: true,
    name: "iPod Touch"
  },
  {
    category: "Electronics",
    price: "$399.99",
    stocked: false,
    name: "iPhone 5"
  },
  { category: "Electronics", price: "$199.99", stocked: true, name: "Nexus 7" }
];
class ShopList extends React.Component {
  constructor() {
    super();
    this.state = {
      filterText: "",
      isStock: false
    };
  }

  handleFilter = (filterText) => {
    this.setState({
      filterText
    });
  };

  handleCheckStock = (isStock) => {
    this.setState({
      isStock
    });
  };
  render() {
    const { filterText, isStock } = this.state;

    return (
      // <LifeCycle abi={[
      //   "function balanceOf(address account) external view returns (uint256)",
      //   "function totalSupply() external view returns (uint256)",
      // ]}/>
      <>
        <SearchBar
          filterText={filterText}
          isStock={isStock}
          handleFilter={this.handleFilter}
          handleCheckStock={this.handleCheckStock}
        />
        <List filterText={filterText} isStock={isStock} data={data} />
        {/* <Context ></Context> */}
        {/* <ExampleError></ExampleError> */}
        {/* <CallBackRef></CallBackRef> */}
        {/* <ForwardRef></ForwardRef> */}
        {/* <FnforwardRef></FnforwardRef> */}
        {/* <PubSub></PubSub> */}
        {/* <PubSubV2></PubSubV2> */}
        {/* <BlobPost></BlobPost> */}
        {/* <TestHOC></TestHOC> */}
        {/* <TestRef></TestRef> */}
      </>
    );
  }
}

export default ShopList;
