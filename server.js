var express = require('express'),
	app = express(),
	oneDay = 86400000,
	port = process.env.PORT || 3000;

app.use(express.compress());
app.use(express.static(__dirname + '/public', {maxAge: oneDay}));
app.use(function(req, res) {
	var newUrl = req.protocol + '://' + req.get('Host') + '/#' + req.url;
	return res.redirect(newUrl);
});

app.listen(port, function() {console.log("listening on " + port); });