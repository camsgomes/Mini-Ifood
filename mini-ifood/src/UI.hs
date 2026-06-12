module UI ( menuCategorias ) where

import Types
import Logic
import qualified Data.Map.Strict as Map
import Data.Char  (toUpper)
import Data.Time  (getCurrentTime, formatTime, defaultTimeLocale)
import System.IO  (hFlush, stdout)

--------------------------------------------------------------------------------
-- Helpers de terminal
--------------------------------------------------------------------------------
prompt :: String -> IO String
prompt msg = do
  putStr msg
  hFlush stdout
  getLine

separador :: IO ()
separador = putStrLn "  ----------------------------------------"

lerOpcao :: String -> Int -> IO Int
lerOpcao msg limite = do
  putStr msg
  opcao <- readLn
  if opcao >= 1 && opcao <= limite
    then return opcao
    else do
      putStrLn "  Opcao invalida. Tente novamente."
      lerOpcao msg limite

lerOpcaoOuZero :: String -> Int -> IO Int
lerOpcaoOuZero msg limite = do
  putStr msg
  opcao <- readLn
  if opcao == 0 || (opcao >= 1 && opcao <= limite)
    then return opcao
    else do
      putStrLn "  Opcao invalida. Digite um numero da lista ou 0 para sair."
      lerOpcaoOuZero msg limite

dataHoje :: IO String
dataHoje = do
  t <- getCurrentTime
  return (formatTime defaultTimeLocale "%Y-%m-%d" t)

--------------------------------------------------------------------------------
-- TELA 1 — Categorias (menu principal / loop raiz)
--------------------------------------------------------------------------------
menuCategorias :: AppState -> IO ()
menuCategorias estado = do
  putStrLn "\n╔══════════════════════════════════════╗"
  putStrLn   "║          Mini-iFood                  ║"
  putStrLn   "╚══════════════════════════════════════╝"
  putStrLn "\n  O que voce quer comer hoje?\n"
  putStr (exibirCategorias (restaurantes estado))
  putStrLn "  0. Sair do aplicativo"
  separador
  
  opcao <- lerOpcaoOuZero "  Escolha: " (length listaDeCategorias)
  
  if opcao == 0
    then putStrLn "\n  Obrigado por usar o Mini-iFood! Ate logo.\n"
    else menuRestaurantes estado (listaDeCategorias !! (opcao - 1))
  where
    listaDeCategorias = categoriasUnicas (restaurantes estado)

--------------------------------------------------------------------------------
-- TELA 2 — Restaurantes da categoria
--------------------------------------------------------------------------------
menuRestaurantes :: AppState -> String -> IO ()
menuRestaurantes estado listaDeCategorias = do
  putStrLn ("\n  === " ++ listaDeCategorias ++ " ===\n")
  putStr (exibirRestaurantes (restaurantes estado) listaDeCategorias)
  separador
  putStrLn "  0. Voltar"
  
  opcao <- lerOpcaoOuZero "  Escolha o restaurante: " (length rests)
  
  if opcao == 0
    then menuCategorias estado
    else menuCardapio estado (nomeRest (rests !! (opcao - 1))) []
  where
    rests = restaurantesPorCategoria (restaurantes estado) listaDeCategorias

--------------------------------------------------------------------------------
-- TELA 3 — Cardápio + loop de adição de itens
--------------------------------------------------------------------------------
menuCardapio :: AppState -> String -> [(Int, Float)] -> IO ()
menuCardapio estado rest itensAtuais = do
  putStr (exibirCardapio rest pratos)
  putStrLn "  0. Fechar pedido e ir ao carrinho"
  separador
  
  opcao <- lerOpcaoOuZero "  Escolha um prato: " (length pratos)
  
  if opcao == 0
    then do
      if itensAtuais == []
        then do
          putStrLn "\n  Carrinho vazio! Adicione pelo menos um item."
          menuCardapio estado rest itensAtuais
        else 
          menuCarrinho estado rest itensAtuais
    else do
      qtdStr <- prompt "  Quantidade: "
      if read qtdStr >= 1
        then 
          menuCardapio estado rest (adicionarItem itensAtuais opcao (read qtdStr))
        else do
          putStrLn "  Quantidade invalida."
          menuCardapio estado rest itensAtuais
  where
    pratos = pratosDoRestaurante (cardapio estado) rest

adicionarItem :: [(Int, Float)] -> Int -> Float -> [(Int, Float)]
adicionarItem [] idx qtd = [(idx, qtd)]
adicionarItem ((i, q):rest) idx qtd
  | i == idx  = (i, q + qtd) : rest
  | otherwise = (i, q) : adicionarItem rest idx qtd

--------------------------------------------------------------------------------
-- TELA 4 — Carrinho
--------------------------------------------------------------------------------
menuCarrinho :: AppState -> String -> [(Int, Float)] -> IO ()
menuCarrinho estado rest itens = do
  putStr (exibirCarrinho (rest, itens) pratos)
  separador
  putStrLn "\n  1. Finalizar pedido"
  putStrLn   "  2. Adicionar mais itens"
  putStrLn   "  3. Cancelar e voltar ao inicio"
  separador
  
  opcao <- lerOpcao "  Escolha: " 3
  
  if opcao == 1
    then checkout estado (rest, itens)
    else if opcao == 2
         then menuCardapio estado rest itens
         else menuCategorias estado
  where
    pratos = pratosDoRestaurante (cardapio estado) rest

--------------------------------------------------------------------------------
-- TELA 5 — Checkout (bairro → endereço → cupom → pagamento → confirmar)
--------------------------------------------------------------------------------
checkout :: AppState -> (String, [(Int, Float)]) -> IO ()
checkout estado (rest, itens) = do
  putStrLn "\n  === Entrega ===\n"
  (frete, bairro) <- etapaBairro taxas
  endereco        <- prompt "  Digite seu endereco (rua e numero): "
  putStrLn ("  Frete para " ++ bairro ++ ": R$ " ++ formatFloat frete)

  putStrLn "\n  === Cupom ===\n"
  desconto <- etapaCupom (cupons estado) subtotal 

  putStrLn "\n  === Pagamento ===\n"
  tipoPag <- etapaPagamento

  exibirResumoFinal pratos (rest, itens) subtotal frete desconto tipoPag (calcularTotal subtotal frete desconto tipoPag) bairro endereco

  resp <- prompt "\n  Confirmar pedido? (s/n): "
  
  if resp == "S" || resp == "s"
    then do
      putStrLn "\n  Pedido realizado com sucesso!"
      putStrLn   "  Aguarde seu delivery!\n"
      menuCategorias estado
    else do
      putStrLn "\n  Pedido cancelado."
      menuCategorias estado
  where
    pratos   = pratosDoRestaurante (cardapio estado) rest
    subtotal = calcularSubtotal (rest, itens) (cardapio estado)
    taxas    = buscaTaxas rest (Map.toList (taxacao estado))

buscaTaxas :: String -> [(String, [a])] -> [a]
buscaTaxas _ [] = []
buscaTaxas nomeBuscado ((nome, ts):resto)
  | nomeBuscado == nome = ts
  | otherwise           = buscaTaxas nomeBuscado resto

--------------------------------------------------------------------------------
-- Etapas do Checkout
--------------------------------------------------------------------------------
etapaBairro :: [(String, Float)] -> IO (Float, String)
etapaBairro [] = do
  putStrLn "  Entrega gratuita!"
  return (0.0, "Centro")
etapaBairro taxas = do
  putStrLn "  Selecione seu bairro:\n"
  imprimeBairros 1 taxas
  separador
  opcao <- lerOpcao "  Bairro: " (length taxas)
  return (extraiRetorno (taxas !! (opcao - 1)))

imprimeBairros :: Int -> [(String, Float)] -> IO ()
imprimeBairros _ [] = return ()
imprimeBairros i ((bairro, _):resto) = do
  putStrLn ("  " ++ show i ++ ". " ++ bairro)
  imprimeBairros (i + 1) resto

extraiRetorno :: (String, Float) -> (Float, String)
extraiRetorno (bairro, frete) = (frete, bairro)

etapaCupom :: MapCupons -> Float -> IO Float
etapaCupom mapC subtotal = do
  putStrLn "  Digite o codigo do cupom (ou Enter para pular):\n"
  codigo <- prompt "  Cupom: "
  
  if codigo == ""
    then do
      putStrLn "  Sem cupom aplicado."
      return 0.0
    else do
      hoje <- dataHoje
      
      -- Avalia a expressão do cupom direto na chamada da função auxiliar, 
      -- sem precisar de let e sem precisar tratar Left/Right!
      imprimeDesconto (aplicarDesconto (verificarCupom codigo subtotal hoje mapC) subtotal)


-- Substitui o processarCupom por um simples verificador de desconto
imprimeDesconto :: Float -> IO Float
imprimeDesconto desconto = do
  if desconto > 0.0
    then putStrLn ("  Desconto aplicado: R$ " ++ formatFloat desconto)
    else putStrLn "  Cupom invalido, expirado ou valor minimo nao atingido."
    
  return desconto

etapaPagamento :: IO TipoPagamento
etapaPagamento = do
  putStrLn "  Forma de pagamento:\n"
  putStrLn "  1. Pix              (sem acrescimo)"
  putStrLn "  2. Credito a vista  (+3%)"
  putStrLn "  3. Credito 2x       (+5%)"
  putStrLn "  4. Credito 3x       (+8%)"
  putStrLn "  5. Credito 4x       (+10%)"
  separador
  opcao <- lerOpcao "  Pagamento: " 5
  return (convertePagamento opcao)

convertePagamento :: Int -> TipoPagamento
convertePagamento 1 = Pix
convertePagamento 2 = CreditoVista
convertePagamento 3 = CreditoParcelado 2
convertePagamento 4 = CreditoParcelado 3
convertePagamento 5 = CreditoParcelado 4
convertePagamento _ = Pix

--------------------------------------------------------------------------------
-- Resumo final
--------------------------------------------------------------------------------
exibirResumoFinal :: [(String, Float)] -> (String, [(Int, Float)]) -> Float -> Float -> Float -> TipoPagamento -> Float -> String -> String -> IO ()
exibirResumoFinal pratos (rest, itens) subtotal frete desconto tipoPag total bairro endereco = do
  putStrLn "\n╔══════════════════════════════════════╗"
  putStrLn   "║          RESUMO DO PEDIDO            ║"
  putStrLn   "╚══════════════════════════════════════╝"
  putStrLn ("\n  Restaurante: " ++ rest)
  putStrLn   "\n  Itens:"
  imprimeItensResumo pratos itens
  separador
  putStrLn ("  Subtotal:          R$ " ++ formatFloat subtotal)
  putStrLn ("  Frete:             R$ " ++ formatFloat frete)
  if desconto > 0
    then putStrLn ("  Desconto (cupom):- R$ " ++ formatFloat desconto)
    else return ()
  putStrLn ("  Forma de pag.:     " ++ descricaoPag tipoPag)
  separador
  putStrLn ("  TOTAL:             R$ " ++ formatFloat total)
  separador
  putStrLn ("  Endereco: " ++ bairro ++ " " ++ endereco)

imprimeItensResumo :: [(String, Float)] -> [(Int, Float)] -> IO ()
imprimeItensResumo _ [] = return ()
imprimeItensResumo pratos (item:resto) = do
  exibirItemResumo pratos item
  imprimeItensResumo pratos resto

exibirItemResumo :: [(String, Float)] -> (Int, Float) -> IO ()
exibirItemResumo pratos (idx, qtd) = do
  putStrLn ("    " ++ show (round qtd :: Int) ++ "x " ++ nome ++ " = R$ " ++ formatFloat (qtd * val))
  where
    (nome, val) = pratos !! (idx - 1)

descricaoPag :: TipoPagamento -> String
descricaoPag Pix                  = "Pix (sem acrescimo)"
descricaoPag CreditoVista         = "Credito a vista (+3%)"
descricaoPag (CreditoParcelado 2) = "Credito 2x (+5%)"
descricaoPag (CreditoParcelado 3) = "Credito 3x (+8%)"
descricaoPag (CreditoParcelado 4) = "Credito 4x (+10%)"
descricaoPag (CreditoParcelado n) = "Credito " ++ show n ++ "x"
