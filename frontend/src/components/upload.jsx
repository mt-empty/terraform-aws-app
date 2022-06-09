import React, { useState, useEffect } from "react";
import { uploadImage } from "../util.js";

const Upload = () => {
  const [selectedImage, setSelectedImage] = useState(null);
  const [submit, setSubmit] = useState(false);
  const [results, setResults] = useState("");

  useEffect(() => {
    upload();
  }, [submit]);

  const upload = async () => {
    if (selectedImage != null) {
      const results = await uploadImage(selectedImage);
      const data = JSON.parse(results.body);
      if (data["results"] != null) {
        setResults(data["results"]);
      } else {
        console.log(data);
        setResults("Error uploading the image");
      }
    }
  };

  return (
    <div>
      <h1>Upload an image</h1>
      <a>Upload an image and get a list of detected objects</a>
      {selectedImage && (
        <div>
          <img width={"500rem"} src={URL.createObjectURL(selectedImage)} />
          <br />
          <a>{selectedImage.name}</a>
          <br />
          <a>
            <button onClick={() => setSelectedImage(null)}>Remove</button>
            <button
              onClick={() =>
                setSubmit(document.getElementById("uploadedImage").files[0])
              }
            >
              Submit
            </button>
          </a>
        </div>
      )}
      <br />

      <br />
      <input
        type="file"
        name="uploadedImage"
        id="uploadedImage"
        onChange={(event) => {
          setSelectedImage(event.target.files[0]);
        }}
      />
      <br />
      <br />
      <>Results:</>
      <br />
      <a>{results}</a>
    </div>
  );
};

export default Upload;
