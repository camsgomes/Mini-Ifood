module FileIO where

import System.IO
import qualified Data.Map as Map
import Types

trim :: String -> String
trim = f . f
  where f = reverse . dropWhile (== ' ')

loadRestaurantes :: IO [(String, String)]
loadRestaurantes = do

    conteudo <- readFile "data/restaurantes.txt"
    let linhas = lines conteudo
    let linhasValidas = filter (\l -> not (null l) && any (== '-') l) linhas
    return (map separarLinha linhasValidas)


separarLinha :: String -> (String, String)
separarLinha linha = 
    let (chave, resto) = break (== '-') linha
    in (trim chave, trim (drop 1 resto))


loadCardapio :: IO Cardapio
loadCardapio = do
    conteudo <- readFile "data/cardapios.txt"
    let blocos = separarPorBlocos (lines conteudo)
    return (Map.fromList (map processarBloco blocos))

separarPorBlocos :: [String] -> [[String]]
separarPorBlocos [] = []
separarPorBlocos liras =
    let (bloco, resto) = break (== "---") liras
    in filter (not . null) bloco : separarPorBlocos (drop 1 resto)

processarBloco :: [String] -> (NomeRestaurante, [(Prato, Preco)])
processarBloco [] = ("", [])
processarBloco (nomeRest : itens) =
    let itensValidos = filter (\i -> any (== '-') i) itens
        pratosComPreco = map extrairPrato itensValidos
    in (trim nomeRest, pratosComPreco)

extrairPrato :: String -> (Prato, Preco)
extrairPrato linha =
    let (nome, precoStr) = break (== '-') linha
        precoLimpo = filter (\c -> c /= ' ' && c /= '$' && c /= 'R') (drop 1 precoStr)
    in (trim nome, read precoLimpo :: Double)


loadTaxacao :: IO Taxacao
loadTaxacao = do
    conteudo <- readFile "data/taxas.txt"
    let linhas = filter (\l -> not (null l) && any (== '-') l) (lines conteudo)
    let listaTuplas = map processarLinhaTaxa linhas
    return (Map.fromListWith (++) [(rest, [(bairro, preco)]) | (rest, bairro, preco) <- listaTuplas])

processarLinhaTaxa :: String -> (NomeRestaurante, Bairro, Preco)
processarLinhaTaxa linha =
    let partes = map trim (splitOn '-' linha)
    in (partes !! 0, partes !! 1, read (partes !! 2) :: Double)

loadCupons :: IO Descontos
loadCupons = do
    conteudo <- readFile "data/cupons.txt"
    let linhas = filter (\l -> not (null l) && any (== '-') l) (lines conteudo)
    return (Map.fromList (map processarLinhaCupom linhas))

processarLinhaCupom :: String -> (CodigoCupom, Cupom)
processarLinhaCupom linha =
    let partes = map trim (splitOn '-' linha)
        cod = partes !! 0
        tipoDesconto = case partes !! 1 of
            "Porcentagem"      -> Porcentagem
            "ValorFixo"         -> ValorFixo
            "PorcentagemFrete" -> PorcentagemFrete
            _                  -> ValorFrete
        val = read (partes !! 2) :: Double
        dataLim = partes !! 3
        valMin = read (partes !! 4) :: Double
    in (cod, Cupom tipoDesconto val dataLim valMin)

splitOn :: Char -> String -> [String]
splitOn c s = case dropWhile (== c) s of
                "" -> []
                s' -> w : splitOn c s''
                      where (w, s'') = break (== c) s'