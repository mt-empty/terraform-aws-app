const express = require("express");
const path = require("path");
const cors = require("cors");
const app = express();
require("dotenv").config({ path: __dirname + "../.env" });
const PORT = process.env.PORT || 3000;

const DIST_DIR = path.join(__dirname, "../dist"); // NEW
const HTML_FILE = path.join(DIST_DIR, "index.html"); // NEW

const whitelist = ["http://localhost:3000", process.env.API_ENDPOINT];
const corsOptions = {
  origin: function (origin, callback) {
    if (whitelist.indexOf(origin) !== -1 || !origin) {
      callback(null, true);
    } else {
      callback(new Error("Not allowed by CORS"));
    }
  },
};

app.use(express.static(DIST_DIR));
app.use(cors(corsOptions));


app.options('*', cors()) // enable pre-flight request for DELETE request
app.get("*", (req, res) => {
  res.sendFile(path.join(__dirname, HTML_FILE));
});

app.post("*", (req, res) => {
  res.sendFile(path.join(__dirname, HTML_FILE));
});

app.listen(PORT, function () {
  console.log(`CORS-enabled web server listening on port ${PORT}`);
});
