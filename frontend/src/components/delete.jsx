import React, { useState } from "react";
import { deleteAnImage, uploadImage } from "../util.js";

const Delete = () => {
  const [inputURL, setInputURL] = useState(null);

  return (
    <div>
      <h1>Delete an image</h1>
      <a>Enter an image url</a>
      <br />

      <br />
      <input
        type="text"
        name="imageURL"
        placeholder="image URL"
        onChange={(event) => {
          console.log(event.target.value);
          setInputURL(event.target.value);
        }}
      />
      <button onClick={() => deleteAnImage(inputURL.trim())}>Delete</button>
    </div>
  );
};

export default Delete;
