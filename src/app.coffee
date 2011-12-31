express = require 'express'
stylus = require 'stylus'
coffee = require './coffee-middleware'
dirname = require('path').dirname

root = dirname __dirname

(app = express.createServer())
	# compilar archivos .styl automaticamente
	.use(stylus.middleware src: "#{root}/views", dest: "#{root}/public")
	# compilar archivos .coffee automaticamente
	.use(coffee src: "#{root}/views", dest: "#{root}/public")
	# servir archivos estaticos
	.use(express.static "#{root}/public")

# servir index.html
app.get '/', (req, res) -> res.sendfile "#{root}/views/index.html"

require('./sync') app

# iniciar el servidor
app.listen 5000