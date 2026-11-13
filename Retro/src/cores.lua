-- Paleta central: troque as cores aqui e o jogo inteiro muda
local Cores = {
	preto      = { 0.06, 0.06, 0.08 },
	fundo      = { 0.11, 0.12, 0.16 },
	chao       = { 0.18, 0.19, 0.24 },
	esteira    = { 0.22, 0.23, 0.28 },
	esteiraLinha = { 0.30, 0.31, 0.37 },
	metal      = { 0.55, 0.58, 0.64 },
	metalEscuro = { 0.34, 0.36, 0.42 },
	laranja    = { 0.95, 0.55, 0.20 },
	laranjaEscuro = { 0.70, 0.36, 0.12 },
	amarelo    = { 0.98, 0.82, 0.30 },
	verde      = { 0.35, 0.85, 0.40 },
	verdeEscuro = { 0.18, 0.52, 0.24 },
	vermelho   = { 0.90, 0.30, 0.30 },
	azul       = { 0.40, 0.70, 0.95 },
	azulEscuro = { 0.22, 0.42, 0.62 },
	branco     = { 0.96, 0.96, 0.98 },
	cinza      = { 0.55, 0.56, 0.62 },
	vidro      = { 0.62, 0.84, 0.98 },
}

-- Cor de cada fase (usada no tema do turno)
Cores.fases = {
	{ 0.95, 0.55, 0.20 },
	{ 0.40, 0.70, 0.95 },
	{ 0.70, 0.45, 0.95 },
}

return Cores