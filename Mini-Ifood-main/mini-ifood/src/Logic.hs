module Logic where

import qualified Data.Map as Map
import Types

exibirCardapio :: NomeRestaurante -> Cardapio -> String
exibirCardapio rest mapaCardapio =
    case Map.lookup rest mapaCardapio of
        Nothing -> "Restaurante nao encontrado."
        Just pratos -> unlines [show i ++ ". " ++ prato ++ " - R$ " ++ show preco 
                               | (i, (prato, preco)) <- zip [1..] pratos]


calcularSubtotal :: NomeRestaurante -> [ItemCarrinho] -> Cardapio -> Double
calcularSubtotal rest itens mapaCardapio =
    case Map.lookup rest mapaCardapio of
        Nothing -> 0.0
        Just pratos -> sum [ precoPrato * fromIntegral qtd 
                           | (idx, qtd) <- itens, 
                             let (nomePrato, precoPrato) = pratos !! (idx - 1)]