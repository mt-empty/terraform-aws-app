import React, { useState, useEffect } from "react";
import { detectImage } from "../util.js";

const Detect = () => {
  const [selectedImage, setSelectedImage] = useState(null);
  const [submit, setSubmit] = useState(false);
  const [results, setResults] = useState([]);

  useEffect(() => {
    detect();
  }, [submit]);

  const detect = async () => {
    if (selectedImage != null) {
      const results = await detectImage(selectedImage);
      const data = JSON.parse(results.body);
      if (data["links"]?.length > 0) {
        setResults(data["links"]);
      } else if (data["links"] == 0) {
        setResults(["No matching images found"]);
      } else {
        console.log(data);
        setResults(["Error detecting the image"]);
      }
    }
  };
  return (
    <div>
      <h1>Detect an image</h1>
      <a>Upload an image tag to get a list of similar images</a>
      {selectedImage && (
        <div>
          <img width={"500rem"} src={URL.createObjectURL(selectedImage)} />
          <br />
          <a>{selectedImage.name}</a>
          <br />
          <a>
            <button
              onClick={() => {
                setSelectedImage(null);
                setResults([]);
              }}
            >
              Remove
            </button>
            <button
              onClick={() =>
                setSubmit(document.getElementById("detectImage").files[0])
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
        name="detectImage"
        id="detectImage"
        onChange={(event) => {
          setSelectedImage(event.target.files[0]);
        }}
      />
      <br />
      <br />
      <>Results:</>
      <br />
      <ol type="1">
        {/* separate string and put them in a list */}
        {results.length > 0 &&
          results.map((item) => (
            <span key={item}>
              <li>{item}</li>
            </span>
          ))}
      </ol>
    </div>
  );
};

export default Detect;
