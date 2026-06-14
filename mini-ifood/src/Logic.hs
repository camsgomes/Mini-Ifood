module Logic
  ( -- Exibição
    exibirCategorias
  , exibirRestaurantes
  , exibirCardapio
  , exibirCarrinho
    -- Cálculo
  , calcularSubtotal
  , calcularFrete
  , verificarCupom
  , aplicarDesconto
  , fatorPagamento
  , calcularTotal
    -- Helpers
  , formatFloat
  , categoriasUnicas
  , restaurantesPorCategoria
  , pratosDoRestaurante
  ) where

import Types
import qualified Data.Map.Strict as Map
import Data.List  (nub, intercalate)
import Data.Char  (toUpper)

-- ---------------------------------------------------------------------------
-- Exibição — todas retornam String para facilitar testes
-- ---------------------------------------------------------------------------

-- Lista as categorias únicas dos restaurantes cadastrados
exibirCategorias :: [Restaurante] -> String
exibirCategorias rests =
  let cats = nub (map categoriaRest rests)
  in  unlines $ zipWith formatLinha [1..] cats
  where
    formatLinha i c = "  " ++ show i ++ ". " ++ c

-- Lista restaurantes filtrados por categoria
exibirRestaurantes :: [Restaurante] -> String -> String
exibirRestaurantes rests cat =
  let filtrados = restaurantesPorCategoria rests cat
  in  unlines $ zipWith formatLinha [1..] filtrados
  where
    formatLinha i r = "  " ++ show i ++ ". " ++ nomeRest r

-- Exibe o cardápio de um restaurante (enumera os pratos)
-- Exemplo:
--   SushiLom
--   1. Temaki de salmao ............. R$ 24,75
--   2. Yaksoba ...................... R$ 37,00
exibirCardapio :: String -> [(String, Float)] -> String
exibirCardapio nomeRestaurante pratos =
  unlines $ cabecalho : zipWith formatPrato [1..] pratos
  where
    cabecalho = "\n  === " ++ nomeRestaurante ++ " ===\n"
    formatPrato i (nome, val) =
      "  " ++ show i ++ ". " ++ paddedNome ++ " R$ " ++ formatFloat val
      where
        paddedNome = nome ++ replicate dots '.' ++ " "
        dots       = max 2 (40 - length nome)

-- Exibe o resumo do carrinho com subtotal
exibirCarrinho :: Carrinho -> [(String, Float)] -> String
exibirCarrinho (rest, itens) pratos =
  unlines $ cabecalho : linhasItens ++ [separador, linhaSubtotal]
  where
    cabecalho     = "\n  === Carrinho — " ++ rest ++ " ===\n"
    separador     = "  " ++ replicate 38 '-'
    linhasItens   = map formatItem itens
    formatItem (idx, qtd) =
      let (nome, val) = pratos !! (idx - 1)
          total       = val * fromIntegral qtd
      in  "  " ++ show qtd ++ "x " ++ nome ++
          " (" ++ formatFloat val ++ ") = R$ " ++ formatFloat total
    subtotal      = calcularSubtotal (rest, itens) (Map.fromList [(rest, pratos)])
    linhaSubtotal = "  Subtotal: R$ " ++ formatFloat subtotal

-- ---------------------------------------------------------------------------
-- Cálculo — funções puras
-- ---------------------------------------------------------------------------

-- Soma de todos os itens do carrinho
calcularSubtotal :: Carrinho -> Cardapio -> Float
calcularSubtotal (rest, itens) card =
  case Map.lookup rest card of
    Nothing     -> 0.0
    Just pratos -> somarItens itens pratos
  where
    -- Condição de parada da recursão (lista vazia)
    somarItens [] carrinho = 0.0
    -- Retorna o valor do frete com proteção contra índice fora dos limites (Safe Indexing)
    somarItens ((idx, qtd):resto) prs
      | idx >= 1  = valorAtual + somarItens resto prs  
      | otherwise = somarItens resto prs
      -- Váriaveis locais
      where
        (carrinho, val)   = prs !! (idx - 1)  
        valorAtual = val * fromIntegral qtd

-- Retorna o valor do frete para o bairro escolhido e recebe a lista de (bairro, taxa) do restaurante
calcularFrete :: [(String, Float)] -> Int -> Float
calcularFrete taxas idx = snd (taxas !! (idx - 1)) 

-- Verifica se o cupom pode ser aplicado 
verificarCupom :: String -> Float -> String -> MapCupons -> Either String Cupom
verificarCupom codigo subtotal hoje mapC =
  case Map.lookup (map toUpper codigo) mapC of
    Nothing -> Left "Cupom nao encontrado."
    Just c
      | subtotal < cupomValorMin c ->
          Left $ "Valor minimo para este cupom: R$ " ++
                 formatFloat (cupomValorMin c)
      | hoje > cupomDataLimite c ->
          Left "Cupom expirado."
      | otherwise -> Right c

-- Aplica o desconto do cupom sobre subtotal e frete 
aplicarDesconto :: Cupom -> Float -> Float -> Float
aplicarDesconto c subtotal frete =
  case cupomTipo c of
    Porcentagem      -> subtotal * (cupomValor c / 100.0)
    ValorFixo        -> min (cupomValor c) subtotal
    ValorFrete       -> min (cupomValor c) frete
    PorcentagemFrete -> frete * (cupomValor c / 100.0)

-- Taxa de acréscimo de acordo com o tipo de pagamento
-- Pix:              x 1.0   (sem acréscimo)
-- Crédito à vista:  x 1.03  (+3%)
-- Crédito 2x:       x 1.05  (+5%)
-- Crédito 3x:       x 1.08  (+8%)
-- Crédito Nx:       x (1 + N * 0.025)
fatorPagamento :: TipoPagamento -> Float
fatorPagamento Pix                  = 1.0
fatorPagamento CreditoVista         = 1.03
fatorPagamento (CreditoParcelado n) = 1.0 + fromIntegral n * 0.025

-- Calcula o total final do pedido
calcularTotal :: Float -> Float -> Float -> TipoPagamento -> Float
calcularTotal subtotal frete desconto tipoPag =
  (subtotal - desconto + frete) * fatorPagamento tipoPag

-- ---------------------------------------------------------------------------
-- Helpers de listagem
-- ---------------------------------------------------------------------------

categoriasUnicas :: [Restaurante] -> [String]
categoriasUnicas = nub . map categoriaRest

restaurantesPorCategoria :: [Restaurante] -> String -> [Restaurante]
restaurantesPorCategoria rests cat = filter ((== cat) . categoriaRest) rests

pratosDoRestaurante :: Cardapio -> String -> [(String, Float)]
pratosDoRestaurante card rest =
  case Map.lookup rest card of
    Just ps -> ps
    Nothing -> []

-- ---------------------------------------------------------------------------
-- Formatação de float para moeda brasileira
-- ---------------------------------------------------------------------------
formatFloat :: Float -> String
formatFloat v =
  let (parteInt, parteDec) = break (== '.') (show (fromIntegral (round (v * 100)) / 100.0 :: Float))
      centavos = take 3 (parteDec ++ ".00")
  in  parteInt ++ centavos