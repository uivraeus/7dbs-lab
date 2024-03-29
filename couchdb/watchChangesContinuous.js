const http = require('http')
const events = require('events');

exports.createWatcher = function(options) {

  const watcher = new events.EventEmitter();

  watcher.host = options.host || 'localhost';
  watcher.port = options.port || 5984;
  watcher.last_seq = options.last_seq || 0;
  watcher.db = options.db || '_users';

  watcher.start = function() {
    const httpOptions = {
      host: watcher.host,
      port: watcher.port,
      path: '/' +
            watcher.db +
            '/_changes' +
            '?feed=continuous&include_docs=true&since=' +
            watcher.last_seq
    };
    
    http.get(httpOptions, function(res) {
      let buffer = '';
      res.on('data', function (chunk) {
        try {
          const document = JSON.parse(chunk);
          if (document) {
            watcher.emit('change', document);
            buffer = ""
          } else {
            console.error(`JSON.parse failed, document=${document}, chunk=${chunk}`);
          }
        } catch (e) {
          // Do nothing (probably newline). Anyway, just try parse the next chunk.
        }
      });
      res.on('end', function() {
        watcher.emit('error', 'End of continuous stream');  
      })
    })
    .on('error', function(err) {
      watcher.emit('error', err);
    });

  };

  return watcher;

};

// start watching couch for changes if running as main script
if (module === require.main) {
  exports.createWatcher({
    db: process.argv[2],
    last_seq: process.argv[3]
  })
    .on('change', console.log)
    .on('error', console.error)
    .start();
}
