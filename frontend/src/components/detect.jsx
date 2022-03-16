import React, { useState} from "react";
import { uploadImage} from '../util.js';

const Detect = () => {
    const [selectedImage, setSelectedImage] = useState(null);
    return (
      <div>
        <h1>Detect an image</h1>
        {selectedImage && (
          <div>
          <img width={"25rem"} src={URL.createObjectURL(selectedImage)} />
          <br />
          <button onClick={()=>setSelectedImage(null)}>Detect</button>
          </div>
        )}
        <br />

        <br />
        <input
          type="file"
          name="imageUpload"
          onChange={(event) => {
            setSelectedImage(event.target.files[0]);
          }}
        />
      </div>
    );
};

export default Detect;