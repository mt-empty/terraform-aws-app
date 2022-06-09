import React, { useState, useEffect } from "react";
import { searchForImage } from "../util.js";

const Search = () => {
  const [inputText, setInputText] = useState("");
  const [results, setResults] = useState("");

  const turnIntoAnArray = (text) => {
    const tags = text.split(",").map((item) => item.trim());
    return tags;
  };

  useEffect(() => {
    search();
  }, [inputText]);

  const search = async () => {
    if (inputText.length > 0) {
      const tags = turnIntoAnArray(inputText);
      const results = await searchForImage(tags);
      const data = JSON.parse(results.body);
      if (data["links"].length > 0) {
        setResults(data["links"]);
      } else {
        setResults([`No image matched with tags: ${tags}`]);
      }
    }
  };

  return (
    <div>
      <h1>Search for images using a tag</h1>
      <a>
        Enter an image tag, multiple tags can be entered by separating them using
        commas
      </a>
      <br />

      <br />
      <input
        type="text"
        name="imageTags"
        id="imageTags"
        placeholder="dog, plane ..."
      />
      <button
        onClick={() => {
          // console.log(document.getElementById("imageTags").value);
          setInputText(document.getElementById("imageTags").value);
        }}
      >
        Search
      </button>

      <br />
      <br />
      <>Results:</>
      <br />
      <ol type="1">
        {/* separate string and put them in a list */}
        {results.length > 0 &&
          results.map((item) => (
            <span key={item}>
              <li>{item}</li>
            </span>
          ))}
      </ol>
    </div>
  );
};

export default Search;
