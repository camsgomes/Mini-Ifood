module FileIO
  ( loadRestaurantes
  , loadCardapio
  , loadTaxacao
  , loadCupons
  ) where

import Types

-- ---------------------------------------------------------------------------
-- loadRestaurantes
-- Le o arquivo de restaurantes e devolve uma lista de Restaurante
-- O arquivo deve estar no formato de lista Haskell, por exemplo:
-- [ Restaurante {nomeRest = "SushiLom", categoriaRest = "Comida japonesa"}
-- , Restaurante {nomeRest = "PastaVita", categoriaRest = "Massas"}
-- ]
-- A funcao read converte o texto do arquivo diretamente para o tipo [Restaurante]
-- ---------------------------------------------------------------------------
loadRestaurantes :: FilePath -> IO [Restaurante]
loadRestaurantes path = do
  conteudo <- readFile path
  return (read conteudo :: [Restaurante])

-- ---------------------------------------------------------------------------
-- loadCardapio
-- Le o arquivo de cardapios e devolve o Cardapio (lista de pares)
-- O arquivo deve estar no formato de lista de tuplas Haskell, por exemplo:
-- [ ("SushiLom", [("Temaki de salmao", 24.75), ("Yaksoba", 37.00)])
-- , ("PastaVita", [("Espaguete ao sugo", 32.00)])
-- ]
-- A funcao read converte o texto e fromList organiza como lista de pares
-- ---------------------------------------------------------------------------
loadCardapio :: FilePath -> IO Cardapio
loadCardapio path = do
  conteudo <- readFile path
  return (read conteudo :: [(String, [(String, Float)])])

-- ---------------------------------------------------------------------------
-- loadTaxacao
-- Le o arquivo de taxas de entrega e devolve a Taxacao (lista de pares)
-- O arquivo deve estar no formato de lista de tuplas Haskell, por exemplo:
-- [ ("SushiLom", [("Centro", 5.00), ("Prata", 7.50)])
-- , ("PastaVita", [("Centro", 4.00), ("Prata", 6.00)])
-- ]
-- ---------------------------------------------------------------------------
loadTaxacao :: FilePath -> IO Taxacao
loadTaxacao path = do
  conteudo <- readFile path
  return (read conteudo :: [(String, [(String, Float)])])

-- ---------------------------------------------------------------------------
-- loadCupons
-- Le o arquivo de cupons e devolve o MapCupons (lista de pares)
-- O arquivo deve estar no formato de lista de tuplas Haskell, por exemplo:
-- [ ("BEMVINDO", Cupom {cupomTipo = Porcentagem, cupomValor = 10.0, ...})
-- , ("FRETE0",   Cupom {cupomTipo = ValorFrete,  cupomValor = 999.0, ...})
-- ]
-- ---------------------------------------------------------------------------
loadCupons :: FilePath -> IO MapCupons
loadCupons path = do
  conteudo <- readFile path
  return (read conteudo :: [(String, Cupom)])