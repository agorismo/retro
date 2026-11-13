local Fases = {}

Fases.lista = {
	{
		nome = "Turno 1 - Estreia",
		meta = 300, duracao = 60,
		intervalo = 1.6, velocidadeBase = 0.08, velocidadeMax = 0.14, aceleracao = 0.001,
	},
	{
		nome = "Turno 2 - Pressão",
		meta = 600, duracao = 70,
		intervalo = 1.3, velocidadeBase = 0.12, velocidadeMax = 0.2, aceleracao = 0.0015,
	},
	{
		nome = "Turno 3 - Turno da noite",
		meta = 1000, duracao = 80,
		intervalo = 1.0, velocidadeBase = 0.15, velocidadeMax = 0.26, aceleracao = 0.002,
	},
}

function Fases.get(n)
	return Fases.lista[n]
end

function Fases.total()
	return #Fases.lista
end

return Fases