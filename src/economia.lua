local Economia = {}

local SAVE_FILE = "save.txt"
local VALOR_BASE = { perfeito = 20, ok = 10, defeito = 0 }

Economia.upgrades = {
	{ id = "zona", nome = "Zona verde maior", desc = "+8% de área perfeita por nível", base = 150, max = 5 },
	{ id = "marcador", nome = "Marcador mais lento", desc = "-10% de velocidade do marcador por nível", base = 120, max = 5 },
	{ id = "esteira", nome = "Esteira mais lenta", desc = "-8% de velocidade da esteira por nível", base = 100, max = 5 },
	{ id = "venda", nome = "Preço melhor", desc = "+15% no valor de cada venda por nível", base = 200, max = 5 },
}

local state = { dinheiro = 0, fase = 1, niveis = {} }

local function resetar()
	state.dinheiro = 0
	state.fase = 1
	state.niveis = {}
	for _, u in ipairs(Economia.upgrades) do
		state.niveis[u.id] = 0
	end
end

function Economia.load()
	resetar()
	if love.filesystem.getInfo(SAVE_FILE) then
		local conteudo = love.filesystem.read(SAVE_FILE) or ""
		for chave, valor in conteudo:gmatch("(%w+)=(%d+)") do
			local n = tonumber(valor)
			if chave == "dinheiro" then
				state.dinheiro = n
			elseif chave == "fase" then
				state.fase = n
			elseif state.niveis[chave] ~= nil then
				state.niveis[chave] = n
			end
		end
	end
end

function Economia.save()
	local linhas = { "dinheiro=" .. state.dinheiro, "fase=" .. state.fase }
	for _, u in ipairs(Economia.upgrades) do
		table.insert(linhas, u.id .. "=" .. state.niveis[u.id])
	end
	love.filesystem.write(SAVE_FILE, table.concat(linhas, "\n"))
end

function Economia.resetarTudo()
	resetar()
	Economia.save()
end

function Economia.getDinheiro()
	return state.dinheiro
end

function Economia.ganhar(valor)
	state.dinheiro = state.dinheiro + valor
end

function Economia.getFase()
	return state.fase
end

function Economia.setFase(n)
	state.fase = n
	Economia.save()
end

function Economia.nivel(id)
	return state.niveis[id]
end

function Economia.custo(u)
	return u.base * (state.niveis[u.id] + 1)
end

function Economia.comprar(u)
	local nivel = state.niveis[u.id]
	if nivel >= u.max then
		return false, "nível máximo"
	end
	local custo = Economia.custo(u)
	if state.dinheiro < custo then
		return false, "sem dinheiro"
	end
	state.dinheiro = state.dinheiro - custo
	state.niveis[u.id] = nivel + 1
	Economia.save()
	return true
end

-- Multiplicadores aplicados pelos upgrades
function Economia.zonaMult()
	return 1 + 0.08 * state.niveis.zona
end

function Economia.marcadorMult()
	return 1 - 0.10 * state.niveis.marcador
end

function Economia.esteiraMult()
	return 1 - 0.08 * state.niveis.esteira
end

function Economia.valorDe(resultado)
	return math.floor(VALOR_BASE[resultado] * (1 + 0.15 * state.niveis.venda))
end

return Economia