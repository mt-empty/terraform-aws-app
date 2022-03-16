import React, { useState} from "react";
import { uploadImage} from '../util.js';

const Search = () => {
    const [selectedImage, setSelectedImage] = useState(null);
    return (
      <div>
        <h1>Search the processed images with a tag</h1>
        {selectedImage && (
          <div>
          <button onClick={()=>setSelectedImage(null)}>Search</button>
          </div>
        )}
        <br />

        <br />
        <input
          type="text"
          name="imageUpload"
          onChange={(event) => {
            setSelectedImage(event.target.files[0]);
          }}
        />
      </div>
    );
};

export default Search;
