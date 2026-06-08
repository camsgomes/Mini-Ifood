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