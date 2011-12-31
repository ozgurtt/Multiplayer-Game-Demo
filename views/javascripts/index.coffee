# caracteres disponibles
chars = ['boy', 'catgirl', 'horngirl', 'pinkgirl', 'princessgirl']

# Un usuario
Usuario = Backbone.Model.extend
	url: 'user'

	initialize: ->
		# monitoriear los cambios de posicion
		@bind 'change:x', @changeX, this
		@bind 'change:y', @changeY, this

		# crear el bitmap
		@bmp = new Bitmap "images/#{@get 'image'}.png"

		# el punto de registro es en el centro
		@bmp.regX = @bmp.image.width*0.5
		@bmp.regY = @bmp.image.height*0.5
		
		# poner justo en la esquina
		if @get('x') is 0
			@set
				x: @bmp.image.width*0.5
				y: @bmp.image.height*0.5
		# o en la otra posicion		
		else
			@set
				x: @get('x')*.99
				y: @get('y')*.99


	# atributos por default
	defaults:
		x: 0
		y: 0
		image: 'boy'
		vel: 5

	# actualizar el grafico
	changeX: -> @bmp.x = @get 'x'
	changeY: -> @bmp.y = @get 'y'
		
	move: (direccion) ->
		# mover el mapa de bits en las diferentes direcciones
		posX = @get 'x'
		posY = @get 'y'

		switch direccion
			when 'left'   then posX -= @get 'vel'
			when 'right'  then posX += @get 'vel'
			when 'top' 	  then posY += @get 'vel'
			when 'bottom' then posY -= @get 'vel'
		
		
		# no mover mas alla de los constraints
		posX = Math.min(@bmp.parent.canvas.width  - @bmp.image.width*0.5, 
			Math.max @bmp.image.width  * 0.5, posX)

		posY = Math.min(@bmp.parent.canvas.height - @bmp.image.height*0.5, 
			Math.max @bmp.image.height * 0.5, posY)

		# actualizar el grafico
		@save x: posX, y: posY

Users = Backbone.Collection.extend url: 'users'

# la vista principal
GameView = Backbone.View.extend
	el: '#micanvas'

	initialize: ->
		# cargar todos los usuarios
		@usuarios = new Users()
		@usuarios.fetch()

		# eventos de la coleccion de usuarios
		@usuarios.bind 'add', @addUser, this
		@usuarios.bind 'remove', @removeUser, this

		# flash stage
		@stage = new Stage @el
		# movimiento con teclas
		@keys = new Keys()

		# configurar "flash"
		Ticker.setFPS 24
		Ticker.addListener this

		# crear este usuario con una imagen aleatoria
		@user = new Usuario
			image: chars[Math.round(Math.random()*(chars.length-1))]

		@user.save()

		@usuarios.add @user

		@sync()

	tick: -> 
		# mover al usuario
		if @keys.isRight then @user.move 'right'
		else if @keys.isLeft then @user.move 'left'

		if @keys.isTop then @user.move 'top'
		else if @keys.isBottom then @user.move 'bottom'

		# actualizar el stage
		@stage.update()
	
	# quitar/agregar al usuario
	addUser: (user) ->  @stage.addChild user.bmp
	removeUser: (user) -> @stage.removeChild user.bmp

	sync: ->
		usuarios =  @usuarios

		findUserById = (id) -> return (usuarios.find (usuario) -> return usuario.id is id)

		syncSocket.on 'read users', (users) ->
			for id, user of users then usuarios.add new Usuario user

		syncSocket.on 'create user', (user) -> 
			myuser = findUserById user.id

			if not myuser then usuarios.add new Usuario user
		
		syncSocket.on 'update user', (user) -> 
			myuser = findUserById user.id
			
			if myuser then myuser.set user
		
		syncSocket.on 'delete user', (id) -> 
			myuser = findUserById id
			if myuser then myuser.destroy()
			
			
# Inicar la aplicación
Zepto ($) -> 
	# precargar las imagenes de los caracteres e iniciar el juego
	loaded = 0

	for char in chars
		img = new Image()
		img.onload =  -> if ++loaded is chars.length then new GameView()
		img.src = "images/#{char}.png"
				


# socket de sincronizacion
syncSocket = io.connect '/' 
Backbone.sync = (method, model, options) ->
	if method is 'create' then syncSocket.once 'now has id', (id) -> model.set id: id

	syncSocket.emit "#{method} #{model.url}", model.attributes
	options.success()
