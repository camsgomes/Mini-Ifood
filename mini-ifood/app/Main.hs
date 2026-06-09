<<<<<<< HEAD
module Main where

import Types
import FileIO
import UI

import qualified Data.Map.Strict as Map
import System.IO        (hSetBuffering, stdout, BufferMode(..))
import System.Exit      (exitSuccess)
import Control.Exception (catch, IOException)

-- ---------------------------------------------------------------------------
-- Caminhos dos arquivos de dados
-- ---------------------------------------------------------------------------
pathRestaurantes :: FilePath
pathRestaurantes = "data/restaurantes.txt"

pathCardapios :: FilePath
pathCardapios = "data/cardapios.txt"

pathTaxas :: FilePath
pathTaxas = "data/taxas.txt"

pathCupons :: FilePath
pathCupons = "data/cupons.txt"

-- ---------------------------------------------------------------------------
-- Main: carrega tudo uma vez e inicia o loop
-- ---------------------------------------------------------------------------
main :: IO ()
main = do
  hSetBuffering stdout NoBuffering

  rests <- carregar "restaurantes" (loadRestaurantes pathRestaurantes) []
  card  <- carregar "cardapios"    (loadCardapio     pathCardapios)    Map.empty
  tax   <- carregar "taxas"        (loadTaxacao      pathTaxas)        Map.empty
  cups  <- carregar "cupons"       (loadCupons       pathCupons)       Map.empty

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

-- ---------------------------------------------------------------------------
-- Carrega um arquivo com fallback silencioso em caso de erro
-- ---------------------------------------------------------------------------
carregar :: String -> IO a -> a -> IO a
carregar nome acao fallback =
  catch acao (handler fallback)
  where
    handler :: a -> IOException -> IO a
    handler fb e = do
      putStrLn $ "[AVISO] Nao foi possivel carregar " ++ nome ++ ": " ++ show e
      return fb
=======
main :: IO () 
main = do 
    putStrLn "Ola, seja bem-vindo ao IFood! :)"
    putStrLn "O que voce deseja pedir hoje?"
    putStrLn "----------------------------------"
    putStrLn "Escolha uma categoria:"
    putStrLn "1 - Comida Japonesa\n2 - Doces\n3 - Pizzas\n4 - Salgados\n5 - Refeicoes\n6 - Cancelar"
    putStrLn "Digite o numero da categoria desejada:"
    categoria <- getLine
    putStrLn "----------------------------------"
    
    case categoria of
        "1" -> menuRestaurante "Comida Japonesa" ["Gendai", "Manihi Sushi", "Sushi Rao"]
        "2" -> menuRestaurante "Doces" ["Milky Moo", "Sodie Doces", "Royal Trudel"]
        "3" -> menuRestaurante "Pizzas" ["Pizza Hut", "Domino's Pizza", "Papa John's"]
        "4" -> menuRestaurante "Salgados" ["Habib's", "McDonald's", "Loucos por Coxinha"]
        "5" -> menuRestaurante "Refeicoes" ["Divino Fogao", "Spoleto", "Viena"]
        "6" -> putStrLn "Pedido cancelado. Obrigado por usar o IFood!"
        _   -> putStrLn "Categoria invalida. Por favor, escolha um numero de 1 a 6."

-- funcao auxiliar para exibir o menu do restaurante escolhido
menuRestaurante :: String -> [String] -> IO ()
menuRestaurante nomeCategoria restaurantes = do
    putStrLn ("Escolha um Restaurante de " ++ nomeCategoria ++ ":")
    putStrLn ("1 - " ++ (restaurantes !! 0))
    putStrLn ("2 - " ++ (restaurantes !! 1))
    putStrLn ("3 - " ++ (restaurantes !! 2))
    putStrLn "4 - Cancelar"
    putStrLn "Digite o numero do restaurante desejado:"
    opcao <- getLine
    putStrLn "----------------------------------"

    putStrLn "CARDAPIO:"
>>>>>>> c85addd4b80e98220dfa0587b53f8bcaa58f6f90
