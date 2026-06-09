module UI where

import Types
import Logic
import qualified Data.Map as Map

menuCategorias :: AppState -> IO ()
menuCategorias state = do
    putStrLn "\n========================================="
    putStrLn "          MINI IFOOD - CATEGORIAS        "
    putStrLn "========================================="
    putStrLn "1 - Comida Japonesa\n2 - Doces\n3 - Pizzas\n4 - Salgados\n5 - Refeicoes\n6 - Sair"
    putStrLn "-----------------------------------------"
    putStrLn "Digite o numero da categoria desejada:"
    opcao <- getLine
    case opcao of
        "1" -> menuRestaurantes state "Comida Japonesa"
        "2" -> menuRestaurantes state "Doces"
        "3" -> menuRestaurantes state "Pizzas"
        "4" -> menuRestaurantes state "Salgados"
        "5" -> menuRestaurantes state "Refeicoes"
        "6" -> putStrLn "Obrigado por usar o Mini-IFood!"
        _   -> do
            putStrLn "Opcao invalida!"
            menuCategorias state


menuRestaurantes :: AppState -> String -> IO ()
menuRestaurantes state categoria = do
    putStrLn $ "\n--- Restaurantes de: " ++ categoria ++ " ---"
    putStrLn "Opcoes disponiveis:"
    if categoria == "Comida Japonesa"
        then putStrLn "- Gendai\n- Manihi_Sushi"
        else putStrLn "- Milky_Moo\n- Sodie_Doces"
        
    putStrLn "-----------------------------------------"
    putStrLn "Digite o nome do Restaurante exatamente como escrito para ver o cardapio:"
    nomeRest <- getLine
    menuCardapio state nomeRest


menuCardapio :: AppState -> NomeRestaurante -> IO ()
menuCardapio state nomeRest = do
    putStrLn $ "\n--- Cardapio: " ++ nomeRest ++ " ---"
    putStrLn $ exibirCardapio nomeRest (cardapioGeral state)
    putStrLn "-----------------------------------------"
    putStrLn "Escolha uma opcao:"
    putStrLn "Digite o numero do prato para adicionar ao carrinho"
    putStrLn "Ou digite '0' para finalizar o pedido"
    
    opcao <- getLine
    if opcao == "0"
        then putStrLn "\nIndo para o carrinho... (Proxima etapa a ser implementada!)"
        else do
            putStrLn "Digite a quantidade:"
            qtdStr <- getLine
            let pratoIdx = read opcao :: Int
            let quantidade = read qtdStr :: Int
            
            let novoCarrinho = (nomeRest, [(pratoIdx, quantidade)])
            let novoEstado = state { carrinhoAtual = novoCarrinho }
            
            putStrLn "Produto adicionado ao carrinho com sucesso!"
            menuCardapio novoEstado nomeRest