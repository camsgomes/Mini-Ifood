module Logic (
  -- Exibição
  exibirCategorias , exibirRestaurantes , exibirCardapio , exibirCarrinho
  -- Cálculo
  , calcularSubtotal , calcularFrete , verificarCupom , aplicarDesconto , fatorPagamento , calcularTotal
  -- Helpers
  , formatFloat , categoriasUnicas , restaurantesPorCategoria , pratosDoRestaurante
) where

import Types
import Data.Char (toUpper)
import qualified Data.Map.Strict as Map

-- Funções de exibição

-- Lista as categorias únicas dos restaurantes
-- Uso de composição de funções
-- Funcionamento:  CategoriasUnicas para limpar a lista removendo duplicatas
-- e sua saída entra na função formataCategorias a partir do indíce 1
exibirCategorias :: [Restaurante] -> String
exibirCategorias rests = formataCategorias 1 (categoriasUnicas rests)

-- Função auxiliar para formatar categorias
-- Uso de recursão e casamento de padrões
-- Funcionamento: Caso base sendo uma lista vazia retornando String vazia
-- Caso recursivo, divide em cabeça(c) e cauda(cs), formata o primeiro elemento e chama a 
-- função recursivamente para o resto da lista, incrementando o índice
formataCategorias :: Int -> [String] -> String
formataCategorias _indice [] = ""
formataCategorias i (c:cs) = "  " ++ show i ++ ". " ++ c ++ "\n" ++ formataCategorias (i + 1) cs

-- Lista restaurantes filtrados
-- Uso de composição de funções
-- Funcionamento:  RestaurantesPorCategoria para filtrar a lista de restaurantes
-- e sua saída entra na função formataRestaurantes a partir do indíce 1
exibirRestaurantes :: [Restaurante] -> String -> String
exibirRestaurantes rests categoria = formataRestaurantes 1 (restaurantesPorCategoria rests categoria)

-- Função auxiliar para formatar restaurantes
-- Uso de recursão e casamento de padrões
-- Funcionamento: Caso base sendo uma lista vazia retornando String vazia
-- Caso recursivo, divide em cabeça(r) e cauda(rs), formata o primeiro elemento e chama a 
-- função recursivamente para o resto da lista, incrementando o índice
formataRestaurantes :: Int -> [Restaurante] -> String
formataRestaurantes _indice [] = ""
formataRestaurantes i (r:rs) = "  " ++ show i ++ ". " ++ nomeRest r ++ "\n" ++ formataRestaurantes (i + 1) rs

-- Exibe o cardápio formatado
-- Uso de composição de funções
-- Funcionamento: recebe a lista de pratos filtrada, monta o cabeçalho
-- com o nome do restaurante e passa os pratos para formataPratos a partir do índice 1
exibirCardapio :: String -> [(String, Float)] -> String
exibirCardapio nomeRestaurante pratos = 
  "\n  === " ++ nomeRestaurante ++ " ===\n\n" ++ formataPratos 1 pratos


-- Função auxiliar para formatar pratos
-- Uso de recursão e casamento de padrões
-- Funcionamento: Caso base lista vazia, retorna nada
-- Caso recursivo abre a lista (nome,val) e a tupla ((nome,val): rest) 
-- ao mesmo tempo, formantando o prato com o nome e seu valor e chamando-se 
-- recursivamente
formataPratos :: Int -> [(String, Float)] -> String
formataPratos _indice [] = ""
formataPratos i ((nome, val):resto) =
  "  " ++ show i ++ ". " ++ padRight nome 30 ++ " R$ " ++ formatFloat val ++ "\n" ++ formataPratos (i + 1) resto

-- Função auxiliar para alinhar o nome do prato 
-- Uso de guardas
-- Funcionamento: Caso o tamanho do nome seja o suficiente
-- retorna o nome normal. Caso o contrário adiciona uma sequência de pontos
-- para deixar o prato alinhado
padRight :: String -> Int -> String
padRight str tamanho
  | length str >= tamanho = str
  | otherwise             = str ++ geraPontos (tamanho - length str)

-- Função auxiliar para gerar a sequencia de pontos utilizada 
-- na formação de strings 
-- Uso de recursão e casamento de padrões
-- Funcionamento: Caso base se o número de pontos a ser adicionado é 
-- igual a zero retorna. Caso recursivo adiciona um ponto e chama a 
-- função novamente.
geraPontos :: Int -> String
geraPontos 0 = ""
geraPontos n = "." ++ geraPontos (n - 1)

-- Exibe o resumo do carrinho
-- Uso de composição de funções
-- Funcionamento: Chama formataItensCarrinho para listar os
-- itens e calculaValor para o retornar o subtotal
exibirCarrinho :: (String, [(Int, Float)]) -> [(String, Float)] -> String
exibirCarrinho (rest, itens) pratos = 
  "\n  === Carrinho — " ++ rest ++ " ===\n\n" ++
  formataItensCarrinho itens pratos ++
  "  ----------------------------------------\n" ++
  "  Subtotal: R$ " ++ formatFloat (calculaValor itens pratos) ++ "\n"

-- Função auxiliar para formatar itens do carrinho
-- Uso de recursão e casamento de padrões
-- Funcionamento: Caso base se a lista vazia retorna. 
-- Caso recursivo ((idx, qtd):resto) abre a lista e a tupla ao mesmo tempo,
-- busca o prato pelo índice com (!!) na cláusula where e formata a linha
-- com quantidade, nome e preço, chamando a si mesma com o resto
formataItensCarrinho :: [(Int, Float)] -> [(String, Float)] -> String
formataItensCarrinho [] _pratos = ""
formataItensCarrinho ((idx, qtd):resto) pratos =
  "  " ++ show (round qtd :: Int) ++ "x " ++ nome ++ " (" ++ formatFloat val ++ ") = R$ " ++ formatFloat (qtd * val) ++ "\n" ++ formataItensCarrinho resto pratos
  where
    (nome, val) = pratos !! (idx - 1)

--------------------------------------------------------------------------------
-- Cálculo — Funções puras aplicando Guardas e Casamento de Padrões
--------------------------------------------------------------------------------

-- Calcula o valor total do carrinho (recursividade com casamento de padrões)
calcularSubtotal :: (String, [(Int, Float)]) -> Cardapio -> Float
calcularSubtotal (rest, itens) card = 
    calculaValor itens (pratosDoRestaurante card rest)

calculaValor :: [(Int, Float)] -> [(String, Float)] -> Float
calculaValor [] parada = 0.0
calculaValor ((idx, qtd):restoItens) pratos = 
    (qtd * valor) + calculaValor restoItens pratos
  where
    (parada, valor) = pratos !! (idx - 1)

calcularFrete :: [(String, Float)] -> Int -> Float
calcularFrete taxas idx = extraiFrete (taxas !! (idx - 1))
  where
    extraiFrete (_, frete) = frete

-- A função principal apenas converte o Map para Lista e repassa para a função recursiva
verificarCupom :: String -> Float -> String -> MapCupons -> Cupom
verificarCupom codigo subtotal hoje mapC = 
  buscaEValidaCupom (map toUpper codigo) subtotal hoje (Map.toList mapC)

{-
  MÉTODO: buscaEValidaCupom
  Usa puramente Recursão e Guardas. 
  Percorre a lista de cupons procurando o código digitado e valida as regras.
-}
buscaEValidaCupom :: String -> Float -> String -> [(String, Cupom)] -> Cupom

-- Caso Base: Se a lista acabou (ou estava vazia) e não achou, retorna um cupom zerado
buscaEValidaCupom _ _ _ [] = Cupom 0.0 "" 0.0

-- Caso Recursivo: Desestrutura a lista pegando o primeiro elemento (cod, cupom) e o resto
buscaEValidaCupom codBuscado subtotal hoje ((cod, cupom):resto)
  
  -- 1ª Guarda: O código bateu E o subtotal é válido E a data está no prazo? Retorna o cupom!
  | codBuscado == cod && subtotal >= cupomValorMin cupom && hoje <= cupomDataLimite cupom = cupom
  
  -- 2ª Guarda: O código bateu, MAS falhou nas regras acima? Retorna cupom zerado!
  | codBuscado == cod = Cupom 0.0 "" 0.0
  
  -- 3ª Guarda (otherwise): O código não é esse. Chama a função de novo passando o resto da lista!
  | otherwise = buscaEValidaCupom codBuscado subtotal hoje resto

-- Aplica o desconto mapeando as opções por Casamento de Padrões
aplicarDesconto :: Cupom -> Float -> Float
aplicarDesconto c subtotal = minimo (cupomValor c) subtotal

-- Função pura auxiliar com Guardas para evitar subtotal negativo
minimo :: Float -> Float -> Float
minimo a b
  | a < b     = a
  | otherwise = b

calculaDesconto :: TipoDesconto -> Float -> Float -> Float -> Float
calculaDesconto Porcentagem      valorCupom subtotal _     = subtotal * (valorCupom / 100.0)
calculaDesconto ValorFixo        valorCupom subtotal _     = minimo valorCupom subtotal
calculaDesconto ValorFrete       valorCupom _        frete = minimo valorCupom frete
calculaDesconto PorcentagemFrete valorCupom _        frete = frete * (valorCupom / 100.0)

-- Fator de pagamento sem fromIntegral e com casamento de padrões explícito
-- Verificar se ficarão só esse mesmo
fatorPagamento :: TipoPagamento -> Float
fatorPagamento Pix          = 1.0
fatorPagamento CreditoVista = 1.03
fatorPagamento Debito       = 1.01


calcularTotal :: Float -> Float -> Float -> TipoPagamento -> Float
calcularTotal subtotal frete desconto tipoPag =
  (subtotal - desconto + frete) * fatorPagamento tipoPag

--------------------------------------------------------------------------------
-- Helpers de listagem — Funções puras e recursivas (Remoção de bibliotecas externas)
--------------------------------------------------------------------------------

-- Extrai as categorias sem duplicatas usando recursão e verificação limpa
categoriasUnicas :: [Restaurante] -> [String]
categoriasUnicas rests = removeDuplicatas (extraiCategorias rests)

extraiCategorias :: [Restaurante] -> [String]
extraiCategorias [] = []
extraiCategorias (r:rs) = categoriaRest r : extraiCategorias rs

removeDuplicatas :: [String] -> [String]
removeDuplicatas [] = []
removeDuplicatas (x:xs)
  | existe x xs = removeDuplicatas xs
  | otherwise   = x : removeDuplicatas xs

existe :: String -> [String] -> Bool
existe _ [] = False
existe elemento (x:xs)
  | elemento == x = True
  | otherwise     = existe elemento xs

-- Filtra os restaurantes usando Guardas
restaurantesPorCategoria :: [Restaurante] -> String -> [Restaurante]
restaurantesPorCategoria [] _ = []
restaurantesPorCategoria (r:rs) cat
  | categoriaRest r == cat = r : restaurantesPorCategoria rs cat
  | otherwise              = restaurantesPorCategoria rs cat

-- Converte a biblioteca Map para Lista nas bordas do sistema, 
-- preservando a manipulação purista internamente.
pratosDoRestaurante :: Cardapio -> String -> [(String, Float)]
pratosDoRestaurante card rest = buscaPratos rest (Map.toList card)

buscaPratos :: String -> [(String, [(String, Float)])] -> [(String, Float)]
buscaPratos _ [] = []
buscaPratos nomeBuscado ((nome, pratos):resto)
  | nomeBuscado == nome = pratos
  | otherwise           = buscaPratos nomeBuscado resto

-- Funções de formatação de float para moeda

-- Converte um Float para String no formato de moeda
-- Uso de guardas
-- Funcionamento: multiplica o valor por 100 e arredonda para transformar
-- em centavos inteiros, converte para String e repassa para formataPositivo.
-- A guarda serve para tratar os valores negativos, que precisam do sinal de menos na frente
formatFloat :: Float -> String
formatFloat v
  | v < 0.0   = "-" ++ formataPositivo (show (round (v * (-100)) :: Int))
  | otherwise = formataPositivo (show (round (v * 100) :: Int))

-- Função auxiliar para inserir o ponto decimal na posição correta
-- Uso de guardas
-- Funcionamento: trata os casos especiais de String curta:
-- 1 dígito ("7") vira "0.07", 2 dígitos ("50") viram "0.50",
-- 3 ou mais dígitos inverte a String e passa para inserePonto
formataPositivo :: String -> String
formataPositivo str
  | length str == 1 = "0.0" ++ str
  | length str == 2 = "0." ++ str
  | otherwise       = inserePonto (reverse str)

-- Função auxiliar para reconstruir a String com o ponto decimal
-- Uso de casamento de padrões em String 
-- Funcionamento: o padrão (c1:c2:resto) captura os dois primeiros caracteres
-- que são os centavos, e resto é a parte inteira ainda invertida
-- depois reconstrói como parte inteira + "." + centavos na ordem correta
inserePonto :: String -> String
inserePonto (c1:c2:resto) = reverse resto ++ "." ++ [c2, c1]
inserePonto _ = "0.00"