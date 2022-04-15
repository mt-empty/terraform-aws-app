import React, { useState } from "react";
import { removeATag } from "../util.js";

const Remove = () => {
  const [inputTagString, setInputTagString] = useState(null);
  const [inputURL, setInputURL] = useState(null);

  const turnIntoAnArray = (text) => {
    const tags = text.split(",").map((item) => item.trim());
    return tags;
  };

  return (
    <div>
      <h1>Remove a tag</h1>
      <a>
        Enter an image tag and an image url, multiple tags can be entered by
        separating them by commas
      </a>
      <br />

      <br />
      <input
        type="text"
        name="imageTags"
        placeholder="dog, plane ..."
        onChange={(event) => {
          console.log(event.target.value);
          setInputTagString(event.target.value);
        }}
      />
      <input
        type="text"
        name="imageURL"
        placeholder="image URL"
        onChange={(event) => {
          console.log(event.target.value);
          setInputURL(event.target.value);
        }}
      />
      <button
        onClick={() =>
          removeATag(turnIntoAnArray(inputTagString), inputURL.trim())
        }
      >
        Remove
      </button>
    </div>
  );
};

export default Remove;
