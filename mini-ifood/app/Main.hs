module Main where

import Types
import FileIO
import UI

import System.IO        (hSetBuffering, stdout, BufferMode(..))
import System.Exit      (exitSuccess)
import Control.Exception (catch, IOException)


-- Caminhos dos arquivos de dados

pathRestaurantes :: FilePath
pathRestaurantes = "data/restaurantes.txt"

pathCardapios :: FilePath
pathCardapios = "data/cardapios.txt"

pathTaxas :: FilePath
pathTaxas = "data/taxas.txt"

pathCupons :: FilePath
pathCupons = "data/cupons.txt"


-- Main: carrega tudo uma vez e inicia o loop

main :: IO ()
main = do
  hSetBuffering stdout NoBuffering

  rests <- carregar "restaurantes" (loadRestaurantes pathRestaurantes) []
  card  <- carregar "cardapios"    (loadCardapio     pathCardapios)    []
  tax   <- carregar "taxas"        (loadTaxacao      pathTaxas)        []
  cups  <- carregar "cupons"       (loadCupons       pathCupons)       []

  if null rests
    then do
      putStrLn "[ERRO] Nenhum restaurante encontrado."
      putStrLn "Verifique o arquivo data/restaurantes.csv"
      exitSuccess
    else do
      let estado = AppState
            { restaurantes = rests
            , cardapio     = card
            , taxacao      = tax
            , cupons       = cups
            }
      menuCategorias estado


-- Carrega um arquivo com fallback silencioso em caso de erro

carregar :: String -> IO a -> a -> IO a
carregar nome acao fallback =
  catch acao (handler fallback)
  where
    handler :: a -> IOException -> IO a
    handler fb e = do
      putStrLn $ "[AVISO] Nao foi possivel carregar " ++ nome ++ ": " ++ show e
      return fb