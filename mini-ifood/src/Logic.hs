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

--------------------------------------------------------------------------------
-- Exibição — Funções puras baseadas em recursividade (substituindo zipWith)
--------------------------------------------------------------------------------

-- Lista as categorias únicas dos restaurantes
exibirCategorias :: [Restaurante] -> String
exibirCategorias rests = formataCategorias 1 (categoriasUnicas rests)

formataCategorias :: Int -> [String] -> String
formataCategorias parada [] = ""
formataCategorias i (c:cs) = "  " ++ show i ++ ". " ++ c ++ "\n" ++ formataCategorias (i + 1) cs

-- Lista restaurantes filtrados
exibirRestaurantes :: [Restaurante] -> String -> String
exibirRestaurantes rests categoria = formataRestaurantes 1 (restaurantesPorCategoria rests categoria)

formataRestaurantes :: Int -> [Restaurante] -> String
formataRestaurantes parada [] = ""
formataRestaurantes i (r:rs) = "  " ++ show i ++ ". " ++ nomeRest r ++ "\n" ++ formataRestaurantes (i + 1) rs

-- Exibe o cardápio formatado
exibirCardapio :: String -> [(String, Float)] -> String
exibirCardapio nomeRestaurante pratos = 
  "\n  === " ++ nomeRestaurante ++ " ===\n\n" ++ formataPratos 1 pratos

formataPratos :: Int -> [(String, Float)] -> String
formataPratos parada [] = ""
formataPratos i ((nome, val):resto) =
  "  " ++ show i ++ ". " ++ padRight nome 30 ++ " R$ " ++ formatFloat val ++ "\n" ++ formataPratos (i + 1) resto

-- Auxiliares de formatação de string (Recursão)
padRight :: String -> Int -> String
padRight str tamanho
  | length str >= tamanho = str
  | otherwise             = str ++ geraPontos (tamanho - length str)

geraPontos :: Int -> String
geraPontos 0 = ""
geraPontos n = "." ++ geraPontos (n - 1)

-- Exibe o resumo do carrinho
exibirCarrinho :: (String, [(Int, Float)]) -> [(String, Float)] -> String
exibirCarrinho (rest, itens) pratos = 
  "\n  === Carrinho — " ++ rest ++ " ===\n\n" ++
  formataItensCarrinho itens pratos ++
  "  ----------------------------------------\n" ++
  "  Subtotal: R$ " ++ formatFloat (calculaValor itens pratos) ++ "\n"

formataItensCarrinho :: [(Int, Float)] -> [(String, Float)] -> String
formataItensCarrinho [] parada = ""
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
fatorPagamento :: TipoPagamento -> Float
fatorPagamento Pix                  = 1.0
fatorPagamento CreditoVista         = 1.03
fatorPagamento (CreditoParcelado 2) = 1.05
fatorPagamento (CreditoParcelado 3) = 1.08
fatorPagamento (CreditoParcelado 4) = 1.10
fatorPagamento (CreditoParcelado _) = 1.0

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

--------------------------------------------------------------------------------
-- Formatação de float para moeda sem usar "fromIntegral"
--------------------------------------------------------------------------------

formatFloat :: Float -> String
formatFloat v
  | v < 0.0   = "-" ++ formataPositivo (show (round (v * (-100)) :: Int))
  | otherwise = formataPositivo (show (round (v * 100) :: Int))

formataPositivo :: String -> String
formataPositivo str
  | length str == 1 = "0.0" ++ str
  | length str == 2 = "0." ++ str
  | otherwise       = inserePonto (reverse str)

-- Aproveita o padrão cabeça/cauda nas Strings (que são listas de Char em Haskell)
inserePonto :: String -> String
inserePonto (c1:c2:resto) = reverse resto ++ "." ++ [c2, c1]
inserePonto _ = "0.00" 