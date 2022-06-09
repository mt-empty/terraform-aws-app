import React, { useState, useEffect } from "react";
import { removeATag } from "../util.js";

const Remove = () => {
  const [inputTagRemoval, setInputTagRemoval] = useState({ tags: "", url: "" });
  const [results, setResults] = useState("");

  const turnIntoAnArray = (text) => {
    const tags = text.split(",").map((item) => item.trim());
    return tags;
  };

  useEffect(() => {
    remove();
  }, [inputTagRemoval]);

  const remove = async () => {
    const tags = turnIntoAnArray(inputTagRemoval.tags);
    const url = inputTagRemoval.url.trim();
    if (tags.length > 0 && url.length > 0) {
      const results = await removeATag(url, tags);
      const data = JSON.parse(results.body);
      console.log(data);
      // if results property exists on data
      if (data["Results"] != null) {
        setResults(data["Results"]);
      } else {
        console.log(data);
        setResults([`No image matched with tags: "${tags}" and url: "${url}"`]);
      }
    }
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
        name="imageTagRemoveTags"
        id="imageTagRemoveTags"
        placeholder="dog, plane ..."
      />
      <input
        type="text"
        name="imageTagRemoveURL"
        id="imageTagRemoveURL"
        placeholder="image URL"
      />
      <button
        onClick={() => {
          // console.log(document.getElementById("imageTagRemoveTags").value);
          // console.log(document.getElementById("imageTagRemoveURL").value);
          setInputTagRemoval({
            tags: document.getElementById("imageTagRemoveTags").value,
            url: document.getElementById("imageTagRemoveURL").value,
          });
        }}
      >
        Submit
      </button>

      <br />
      <br />
      <>Results:</>
      <br />
      <a>{results}</a>
    </div>
  );
};

export default Remove;
