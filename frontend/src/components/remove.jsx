import React, { useState} from "react";
import { uploadImage} from '../util.js';

const Remove = () => {
    const [selectedImage, setSelectedImage] = useState(null);
    return (
      <div>
        <h1>Remove a tag</h1>
        {selectedImage && (
          <div>
          <img width={"25rem"} src={URL.createObjectURL(selectedImage)} />
          <br />
          <button onClick={()=>setSelectedImage(null)}>Remove</button>
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

export default Remove;
