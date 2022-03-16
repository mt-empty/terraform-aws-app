const express = require('express')
const path = require('path');
const cors = require('cors')
const app = express()
// require('dotenv').config({path:__dirname+'../.env'})
require('dotenv').config({ debug: true })
const PORT = process.env.PORT || 3000;

const DIST_DIR = path.join(__dirname, '../dist'); // NEW
const HTML_FILE = path.join(DIST_DIR, 'index.html'); // NEW

const whitelist = ['http://localhost:3000', process.env.API_ENDPOINT]
const corsOptions = {
  origin: function (origin, callback) {
    if (whitelist.indexOf(origin) !== -1) {
      callback(null, true)
    } else {
      callback(new Error('Not allowed by CORS'))
    }
  }
}

// app.use(cors(corsOptions));
app.use(express.static(DIST_DIR));

// app.get("/", (req, res) => {
//   res.sendFile(path.join(__dirname, HTML_FILE));
// });


app.get('*', cors(corsOptions), (req, res, next) => {
  res.json({msg: 'This is CORS-enabled for a whitelisted domain.'})
})

app.listen(PORT, function () {
  console.log(`CORS-enabled web server listening on port ${PORT}`)
})
