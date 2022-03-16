import React, { useState} from "react";
import { uploadImage} from '../util.js';

const Upload = () => {
    const [selectedImage, setSelectedImage] = useState(null);
    return (
      <div>
        <h1>Upload an image</h1>
        {selectedImage && (
          <div>
          <img width={"500rem"} src={URL.createObjectURL(selectedImage)} />
          <br />
          <button onClick={()=>setSelectedImage(null)}>Remove</button>
          <br />
          <p> {selectedImage.name} </p>
          <button onClick={()=>uploadImage(selectedImage)}>Submit</button>
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

export default Upload;
