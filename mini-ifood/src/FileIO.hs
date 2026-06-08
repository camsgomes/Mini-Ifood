module FileIO
  ( loadRestaurantes
  , loadCardapio
  , loadTaxacao
  , loadCupons
  ) where

import Types
import qualified Data.Map.Strict as Map

-- ---------------------------------------------------------------------------
-- Carrega restaurantes
-- ---------------------------------------------------------------------------
loadRestaurantes :: FilePath -> IO [Restaurante]
loadRestaurantes path = do
  conteudo <- readFile path
  return (read conteudo :: [Restaurante])

-- ---------------------------------------------------------------------------
-- Carrega cardápios
-- ---------------------------------------------------------------------------
loadCardapio :: FilePath -> IO Cardapio
loadCardapio path = do
  conteudo <- readFile path
  -- Lemos como uma lista de tuplas e convertemos para Map
  let lista = read conteudo :: [(String, [(String, Float)])]
  return (Map.fromList lista)

-- ---------------------------------------------------------------------------
-- Carrega taxas de entrega
-- ---------------------------------------------------------------------------
loadTaxacao :: FilePath -> IO Taxacao
loadTaxacao path = do
  conteudo <- readFile path
  let lista = read conteudo :: [(String, [(String, Float)])]
  return (Map.fromList lista)

-- ---------------------------------------------------------------------------
-- Carrega cupons
-- ---------------------------------------------------------------------------
loadCupons :: FilePath -> IO MapCupons
loadCupons path = do
  conteudo <- readFile path
  let lista = read conteudo :: [(String, Cupom)]
  return (Map.fromList lista)