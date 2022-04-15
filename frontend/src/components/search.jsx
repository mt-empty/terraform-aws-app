import React, { useState } from "react";
import { searchForImage } from "../util.js";

const Search = () => {
  const [inputText, setInputText] = useState(null);

  const turnIntoAnArray = (text) => {
    const tags = text.split(",").map((item) => item.trim());
    return tags;
  };

  return (
    <div>
      <h1>Search the processed images using a tag</h1>
      <a>Enter an image tag, multiple tags can be entered by separating them by commas</a>
      <br />

      <br />
      <input
        type="text"
        name="imageTags"
        placeholder="dog, plane ..."
        onChange={(event) => {
          console.log(event.target.value)
          setInputText(event.target.value);
        }}
      />
      <button onClick={() => searchForImage(turnIntoAnArray(inputText))}>
        Search
      </button>
    </div>
  );
};

export default Search;
