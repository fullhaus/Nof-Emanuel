const express = require('express')
const app = express()
const port = 3000

app.get('/', (req, res) => {
  res.send('Hello World! - It is NOF EMANUEL APP');
})

app.get('/health-check', (req, res) => {
    res.status(200).send('Ok');
  })

app.listen(port, () => {
  console.log(`App listening on port ${port}`)
})