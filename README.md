# Fábrica de Retrovisores

Um jogo de gestão de linha de produção feito com [LÖVE (Love2D)](https://love2d.org/) em Lua. Você pega as peças que passam pela esteira, monta no posto no tempo certo e vende os retrovisores para bater a meta de cada turno.

## Como jogar

1. Uma peça aparece na esquerda e anda pela esteira.
2. Quando ela chega na zona do **POSTO**, clique nela para pegá-la.
3. Um marcador oscila na barra do minijogo. Aperte **ESPAÇO** ou clique quando ele estiver na faixa:
   - **Verde:** montagem perfeita, vale mais.
   - **Amarela:** montagem ok.
   - **Fora das faixas:** defeito, não vale nada.
4. Peças que passam sem serem pegas contam como perdidas.
5. Cada turno tem uma **meta de lucro** e um **tempo limite**. Bata a meta para avançar.
6. Entre os turnos, use o dinheiro na **loja** para melhorar a fábrica.

### Upgrades

| Upgrade | Efeito por nível | Máximo |
|---|---|---|
| Zona verde maior | +8% de área perfeita | 5 |
| Marcador mais lento | -10% de velocidade do marcador | 5 |
| Esteira mais lenta | -8% de velocidade da esteira | 5 |
| Preço melhor | +15% no valor de cada venda | 5 |

## Requisitos

- [LÖVE 11.x](https://love2d.org/) instalado no seu sistema.

## Como rodar

Pelo terminal, a partir da pasta do projeto:

```bash
love .
```

Ou arraste a pasta do projeto para cima do executável do LÖVE.

## Controles

| Tecla / ação | Função |
|---|---|
| Clique / ESPAÇO | Pegar peça e montar |
| ENTER | Iniciar fase, próxima fase ou voltar |
| L (no menu) | Abrir loja |
| 1 a 4 (na loja) | Comprar upgrade |
| R (durante a fase) |
