var express = require('express'),
	app = express(),
	oneDay = 86400000,
	port = process.env.PORT || 3000;

app.use(express.compress());
app.use(express.static(__dirname + '/public', {maxAge: oneDay}));
app.listen(port, function() {console.log("listening on " + port); });