module Main where

import Types
import FileIO
import UI
import qualified Data.Map as Map

main :: IO ()
main = do
    putStrLn "========================================="
    putStrLn "     INICIALIZANDO MINI-IFOOD REAL...    "
    putStrLn "========================================="
    
    cardapioReal <- loadCardapio
    taxasReais   <- loadTaxacao
    cuponsReais  <- loadCupons
    

    let estadoInicial = AppState {
        cardapioGeral = cardapioReal,
        taxacaoGeral  = taxasReais,
        cuponsGeral   = cuponsReais,
        carrinhoAtual = ("", [])
    }
    
    putStrLn "Sucesso: Todos os ficheiros da base de dados foram carregados!"
    
    menuCategorias estadoInicial