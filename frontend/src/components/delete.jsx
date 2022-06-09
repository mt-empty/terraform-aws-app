import React, { useState, useEffect } from "react";
import { deleteAnImage } from "../util.js";

const Delete = () => {
  const [inputURL, setInputURL] = useState("");
  const [results, setResults] = useState("");

  useEffect(() => {
    deleteImage();
  }, [inputURL]);

  const deleteImage = async () => {
    const url = inputURL.trim();
    if (url.length > 0) {
      const results = await deleteAnImage(url);
      console.log(results);
      const data = JSON.parse(results.body);
      console.log(data);
      if (data["Results"] != null) {
        setResults(data["Results"]);
      } else {
        console.log(data);
        setResults([`No image matched the url: "${url}"`]);
      }
    }
  };

  return (
    <div>
      <h1>Delete an image</h1>
      <a>Enter an image url</a>
      <br />

      <br />
      <input
        type="text"
        name="deleteImageURL"
        id="deleteImageURL"
        placeholder="image URL"
      />
      <button
        onClick={() =>
          setInputURL(document.getElementById("deleteImageURL").value)
        }
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

export default Delete;
