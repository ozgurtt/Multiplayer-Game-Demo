module.exports =  (app) ->
	redis = require('redis').createClient()

	redis.flushall()

	io = require('socket.io').listen(app)

	io.sockets.on 'connection', (socket) ->
		userId = -1

		# leer los elementos guardados en la base de datos (usuarios)
		socket.on 'read users',  ->
			redis.hgetall 'users', (err, users) ->
				# transformar los elementos (jsonstring) en objeto
				for id of users then users[id] = JSON.parse users[id]

				socket.emit 'read users', users
		
		# guardar un elemento en la base de datos (usuario)
		socket.on 'create user', (user) ->
			# obtener el id
			redis.incr "next:users", (err, id) ->
				
				user = user
				user.id = id
				# de hecho es el id de este usuario
				userId = id

				# guardar el elemento en la base de datos
				redis.hmset 'users', id, JSON.stringify(user)

				socket.emit 'now has id', id

				# enviar el update a todos
				socket.broadcast.emit 'create user', user

		# enviar los cambios de movimiento
		socket.on 'update user', (user) ->
			redis.hmset 'users', user.id, JSON.stringify user

			socket.volatile.broadcast.emit 'update user', user

		# eliminar un elemento (usuario)
		socket.on 'disconnect', ->
			redis.hdel 'users', userId

			socket.broadcast.emit 'delete user', userId
