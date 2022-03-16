import React, { useState} from "react";
import { uploadImage} from '../util.js';

const Delete = () => {
    const [selectedImage, setSelectedImage] = useState(null);
    return (
      <div>
        <h1>Delete an image</h1>
        {selectedImage && (
          <div>
          <button onClick={()=>setSelectedImage(null)}>Delete</button>
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

export default Delete;
