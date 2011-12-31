# Eventos de ir para arriba, para abajo y a los lados
class window.Keys
	constructor: ->
		document.addEventListener 'keydown', (e) =>
			switch e.keyCode
				# derecha
				when 68 then @isRight = yes
				# izquierda
				when 65 then @isLeft = yes
				# arriba
				when 83 then @isTop = yes
				# abajo
				when 87 then @isBottom = yes

		, false

		document.addEventListener 'keyup', (e) =>
			switch e.keyCode
				# derecha
				when 68 then @isRight = no
				# izquierda
				when 65 then @isLeft = no
				# arriba
				when 83 then @isTop = no
				# abajo
				when 87 then @isBottom = no
		, false