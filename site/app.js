const express = require('express')
var pg = require('pg');
const env = process.env
const app = express()
const port = 3000

// 静的読み込み。
app.use('/static', express.static(__dirname + '/public'));

var fs = require('fs') // this engine requires the fs module
app.engine('ejs', function (filePath, options, callback) { // define the template engine
  fs.readFile(filePath, function (err, content) {
    if (err) return callback(err)
    // this is an extremely simple template engine
    var rendered = content.toString()
      .replace('#title#', '<title>' + options.title + '</title>')
      .replace('#message#', '<h1>' + options.message + '</h1>')
    return callback(null, rendered)
  })
})
app.set('views', './views') // specify the views directory
app.set('view engine', 'ejs') // register the template engine

app.use((req, res) => {
  res.sendStatus(404);
});

app.get('/', function (req, res) {
  res.render('index', { title: 'Hey', message: 'Hello there!' })
})

app.get('/recommend', function (req, res) {

  // var pool = pg.Pool({
  //   database: 'mydb',
  //   user: 'postgres', //ユーザー名はデフォルト以外を利用している人は適宜変更してください。
  //   password: 'PASSWORD', //PASSWORDにはPostgreSQLをインストールした際に設定したパスワードを記述。
  //   host: 'localhost',
  //   port: 5432,
  // });
  // pool.connect( function(err, client) {
  //   if (err) {
  //     console.log(err);
  //   } else {
  //     client.query('SELECT name FROM staff', function (err, result) {
  //       res.render('index', {
  //         title: 'Express',
  //         datas: result.rows[0].name,
  //       });
  //       console.log(result); //コンソール上での確認用なため、この1文は必須ではない。
  //     });
  //   }
  // });
  res.render('recommend', { title: 'Hey', message: 'Hello there!' })
})

app.get('/about', function (req, res) {
  res.render('about', { title: 'Hey', message: 'Hello there!' })
})

app.listen(port, () => {
  console.log(`Example app listening at http://localhost:${port}`)
})