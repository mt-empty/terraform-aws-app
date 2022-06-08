import React, { useState, useRef } from "react";
import Upload from '/src/components/upload.jsx';
import Detect from '/src/components/detect.jsx';
import Search from '/src/components/search.jsx';
import Remove from '/src/components/remove.jsx';
import Delete from '/src/components/delete.jsx';

function App() {
  return (
    <div>
      <Upload/>
      <Detect/>
      <Search/>
      <Remove/>
      <Delete/>
    </div>
  );
};

export default App;
