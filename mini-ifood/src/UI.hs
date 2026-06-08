module UI
  ( menuCategorias
  ) where

import Types
import Logic
import qualified Data.Map.Strict as Map
import Data.Char  (toUpper)
import Data.Time  (getCurrentTime, formatTime, defaultTimeLocale)
import System.IO  (hFlush, stdout)

-- ---------------------------------------------------------------------------
-- Helpers de terminal
-- ---------------------------------------------------------------------------

prompt :: String -> IO String
prompt msg = do
  putStr msg
  hFlush stdout
  getLine

separador :: IO ()
separador = putStrLn $ "  " ++ replicate 40 '-'

lerOpcao :: String -> Int -> IO Int
lerOpcao msg limite = do
  entrada <- prompt msg
  case reads entrada of
    [(n, "")] | n >= 1 && n <= limite -> return n
    _ -> do
      putStrLn "  Opcao invalida. Tente novamente."
      lerOpcao msg limite

lerOpcaoOuZero :: String -> Int -> IO Int
lerOpcaoOuZero msg limite = do
  entrada <- prompt msg
  case reads entrada of
    [(0, "")] -> return 0
    [(n, "")] | n >= 1 && n <= limite -> return n
    _ -> do
      putStrLn "  Opcao invalida. Digite um numero da lista ou 0 para sair."
      lerOpcaoOuZero msg limite

dataHoje :: IO String
dataHoje = do
  t <- getCurrentTime
  return $ formatTime defaultTimeLocale "%Y-%m-%d" t

-- ---------------------------------------------------------------------------
-- TELA 1 — Categorias (menu principal / loop raiz)
-- ---------------------------------------------------------------------------
menuCategorias :: AppState -> IO ()
menuCategorias estado = do
  let cats = categoriasUnicas (restaurantes estado)
  putStrLn "\n╔══════════════════════════════════════╗"
  putStrLn   "║          Mini-iFood                  ║"
  putStrLn   "╚══════════════════════════════════════╝"
  putStrLn "\n  O que voce quer comer hoje?\n"
  putStr $ exibirCategorias (restaurantes estado)
  putStrLn "  0. Sair do aplicativo"
  separador
  opcao <- lerOpcaoOuZero "  Escolha: " (length cats)
  case opcao of
    0 -> putStrLn "\n  Obrigado por usar o Mini-iFood! Ate logo.\n"
    _ -> do
      let catEscolhida = cats !! (opcao - 1)
      menuRestaurantes estado catEscolhida

-- ---------------------------------------------------------------------------
-- TELA 2 — Restaurantes da categoria
-- ---------------------------------------------------------------------------
menuRestaurantes :: AppState -> String -> IO ()
menuRestaurantes estado cat = do
  let rests = restaurantesPorCategoria (restaurantes estado) cat
  putStrLn $ "\n  === " ++ cat ++ " ===\n"
  putStr $ exibirRestaurantes (restaurantes estado) cat
  separador
  putStrLn "  0. Voltar"
  opcao <- lerOpcaoOuZero "  Escolha o restaurante: " (length rests)
  case opcao of
    0 -> menuCategorias estado
    _ -> do
      let rest = nomeRest (rests !! (opcao - 1))
      menuCardapio estado rest []

-- ---------------------------------------------------------------------------
-- TELA 3 — Cardápio + loop de adição de itens
-- ---------------------------------------------------------------------------
menuCardapio :: AppState -> String -> [(Int, Int)] -> IO ()
menuCardapio estado rest itensAtuais = do
  let pratos = pratosDoRestaurante (cardapio estado) rest
  putStr $ exibirCardapio rest pratos
  putStrLn "  0. Fechar pedido e ir ao carrinho"
  separador
  opcao <- lerOpcaoOuZero "  Escolha um prato: " (length pratos)
  case opcao of
    0 -> do
      if null itensAtuais
        then do
          putStrLn "\n  Carrinho vazio! Adicione pelo menos um item."
          menuCardapio estado rest itensAtuais
        else menuCarrinho estado rest itensAtuais
    idx -> do
      qtdStr <- prompt $ "  Quantidade: "
      case reads qtdStr of
        [(q, "")] | q >= 1 -> do
          let novosItens = adicionarItem itensAtuais idx q
          menuCardapio estado rest novosItens
        _ -> do
          putStrLn "  Quantidade invalida."
          menuCardapio estado rest itensAtuais

-- Adiciona item ao carrinho: se já existe o índice, soma a quantidade
adicionarItem :: [(Int, Int)] -> Int -> Int -> [(Int, Int)]
adicionarItem [] idx qtd = [(idx, qtd)]
adicionarItem ((i, q):rest) idx qtd
  | i == idx  = (i, q + qtd) : rest
  | otherwise = (i, q) : adicionarItem rest idx qtd

-- ---------------------------------------------------------------------------
-- TELA 4 — Carrinho
-- ---------------------------------------------------------------------------
menuCarrinho :: AppState -> String -> [(Int, Int)] -> IO ()
menuCarrinho estado rest itens = do
  let pratos = pratosDoRestaurante (cardapio estado) rest
  putStr $ exibirCarrinho (rest, itens) pratos
  separador
  putStrLn "\n  1. Finalizar pedido"
  putStrLn   "  2. Adicionar mais itens"
  putStrLn   "  3. Cancelar e voltar ao inicio"
  separador
  opcao <- lerOpcao "  Escolha: " 3
  case opcao of
    1 -> checkout estado (rest, itens)
    2 -> menuCardapio estado rest itens
    _ -> menuCategorias estado

-- ---------------------------------------------------------------------------
-- TELA 5 — Checkout (bairro → endereço → cupom → pagamento → confirmar)
-- ---------------------------------------------------------------------------
checkout :: AppState -> Carrinho -> IO ()
checkout estado carrinho@(rest, _) = do
  let pratos   = pratosDoRestaurante (cardapio estado) rest
      subtotal = calcularSubtotal carrinho (cardapio estado)
      taxas    = case Map.lookup rest (taxacao estado) of
                   Just ts -> ts
                   Nothing -> []

  -- 5.1 Bairro e endereço
  putStrLn "\n  === Entrega ===\n"
  (frete, bairro) <- etapaBairro taxas
  endereco        <- prompt "  Digite seu endereco (rua e numero): "
  putStrLn $ "  Frete para " ++ bairro ++ ": R$ " ++ formatFloat frete

  -- 5.2 Cupom
  putStrLn "\n  === Cupom ===\n"
  desconto <- etapaCupom (cupons estado) subtotal frete

  -- 5.3 Pagamento
  putStrLn "\n  === Pagamento ===\n"
  tipoPag <- etapaPagamento

  -- 5.4 Resumo e confirmação
  let total = calcularTotal subtotal frete desconto tipoPag
  exibirResumoFinal pratos carrinho subtotal frete desconto tipoPag total bairro endereco

  resp <- prompt "\n  Confirmar pedido? (s/n): "
  case map toUpper resp of
    "S" -> do
      putStrLn "\n  Pedido realizado com sucesso!"
      putStrLn   "  Aguarde seu delivery!\n"
      menuCategorias estado
    _ -> do
      putStrLn "\n  Pedido cancelado."
      menuCategorias estado

-- ---------------------------------------------------------------------------
-- Etapa do bairro
-- ---------------------------------------------------------------------------
etapaBairro :: [(String, Float)] -> IO (Float, String)
etapaBairro [] = do
  putStrLn "  Entrega gratuita!"
  return (0.0, "Centro")
etapaBairro taxas = do
  putStrLn "  Selecione seu bairro:\n"
  mapM_ (\(i, (b, _)) -> 
    putStrLn $ "  " ++ show i ++ ". " ++ b)
    (zip [1..] taxas)
  separador
  opcao <- lerOpcao "  Bairro: " (length taxas)
  let (bairro, frete) = taxas !! (opcao - 1)
  return (frete, bairro)

-- ---------------------------------------------------------------------------
-- Etapa do cupom
-- ---------------------------------------------------------------------------
etapaCupom :: MapCupons -> Float -> Float -> IO Float
etapaCupom mapC subtotal frete = do
  putStrLn "  Digite o codigo do cupom (ou Enter para pular):\n"
  codigo <- prompt "  Cupom: "
  if null codigo
    then do
      putStrLn "  Sem cupom aplicado."
      return 0.0
    else do
      hoje <- dataHoje
      case verificarCupom codigo subtotal hoje mapC of
        Left err -> do
          putStrLn $ "  " ++ err
          return 0.0
        Right c -> do
          let desc = aplicarDesconto c subtotal frete
          putStrLn $ "  Desconto aplicado: R$ " ++ formatFloat desc
          return desc

-- ---------------------------------------------------------------------------
-- Etapa do pagamento
-- ---------------------------------------------------------------------------
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
  return $ case opcao of
    1 -> Pix
    2 -> CreditoVista
    3 -> CreditoParcelado 2
    4 -> CreditoParcelado 3
    5 -> CreditoParcelado 4
    _ -> Pix

-- ---------------------------------------------------------------------------
-- Resumo final
-- ---------------------------------------------------------------------------
exibirResumoFinal
  :: [(String, Float)]
  -> Carrinho
  -> Float -> Float -> Float
  -> TipoPagamento -> Float
  -> String -> String
  -> IO ()
exibirResumoFinal pratos (rest, itens) subtotal frete desconto tipoPag total bairro endereco = do
  putStrLn "\n╔══════════════════════════════════════╗"
  putStrLn   "║          RESUMO DO PEDIDO            ║"
  putStrLn   "╚══════════════════════════════════════╝"
  putStrLn $ "\n  Restaurante: " ++ rest
  putStrLn   "\n  Itens:"
  mapM_ (exibirItemResumo pratos) itens
  separador
  putStrLn $ "  Subtotal:          R$ " ++ formatFloat subtotal
  putStrLn $ "  Frete (" ++ bairro ++ "):  R$ " ++ formatFloat frete
  if desconto > 0
    then putStrLn $ "  Desconto (cupom):- R$ " ++ formatFloat desconto
    else return ()
  putStrLn $ "  Forma de pag.:     " ++ descricaoPag tipoPag
  separador
  putStrLn $ "  TOTAL:             R$ " ++ formatFloat total
  separador
  putStrLn $ "  Endereco: " ++ endereco

exibirItemResumo :: [(String, Float)] -> (Int, Int) -> IO ()
exibirItemResumo pratos (idx, qtd) = do
  let (nome, val) = pratos !! (idx - 1)
  putStrLn $ "    " ++ show qtd ++ "x " ++ nome ++
             " = R$ " ++ formatFloat (val * fromIntegral qtd)

descricaoPag :: TipoPagamento -> String
descricaoPag Pix                  = "Pix (sem acrescimo)"
descricaoPag CreditoVista         = "Credito a vista (+3%)"
descricaoPag (CreditoParcelado n) = "Credito " ++ show n ++ "x (+" ++
  show (round (fatorPagamento (CreditoParcelado n) * 100 - 100) :: Int) ++ "%)"