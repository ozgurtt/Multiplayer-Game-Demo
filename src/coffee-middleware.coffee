# copia del middleware de stylus

url = require 'url'
join = require('path').join
dirname = require('path').dirname
fs = require 'fs'
coffee = require 'coffee-script'
mkdirp = require 'mkdirp'

module.exports = (options) ->
	options = options || {}

	force = options.force
	src = options.src

	# la opcion de origen es necesaria
	if not src then throw new Error 'coffeescriptmiddleware() requiere directorio "src"'

	# si no hay destino utilizar el origen
	dest = if options.dest then options.dest else src

	# devolver el middleware
	return (req, res, next) ->
		# solo en solicitudes get o head
		if req.method isnt 'GET' and req.method istn 'HEAD' then return next()

		# la direccion del archivo sin el http://dominio
		path = url.parse(req.url).pathname

		# verificar que sea un archivo javascript
		if /\.js$/.test path
			jsPath = join dest, path # el archivo javascript
			coffeePath = join src, path.replace '.js', '.coffee' # el archivo coffeescript
			
			error = (err) ->
				next if 'ENOENT' is err.code then null else err
			
			# flag para forzar la compilacion siempre		
			if force then return compile()


			compile = ->
				# leer el archivo
				fs.readFile coffeePath, 'utf8', (err, str) ->
					if err then return error err
					
					# crear los subdirectorios/directorios necesarios
					mkdirp dirname(jsPath), 0700, (err) ->
						if err then return next err	

						# grabar el archivo al disco compilado
						fs.writeFile jsPath, coffee.compile(str), 'utf-8', next

			# verificar si el archivo fue modificado, de ser asi recompilar			
			fs.stat coffeePath, (err, coffeeStats) ->
				if err then return error err

				fs.stat jsPath, (err, jsStats) ->
					if err
						if 'ENOENT' is err.code then compile()
						else next err
					
					else
						if coffeeStats.mtime > jsStats.mtime then compile()
						else next()
							
		else
			return next()
	