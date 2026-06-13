module UI ( menuCategorias ) where

import Types
import Logic
import Data.Time  (getCurrentTime, formatTime, defaultTimeLocale)
import System.IO  (hFlush, stdout)


-- Funções Auxiliares de Visualização do Sistema

-- Impressão de mensagem e captura de entrada na mesma linha
-- Funcionamento: Exibe o texto enviado no parâmetro e utiliza hFlush stdout 
-- para garantir a exibição imediata no terminal antes de aguardar a leitura do getLine
prompt :: String -> IO String
prompt msg = do
  putStr msg
  hFlush stdout
  getLine

-- Captura e validação de opções
-- Uso de recursão e estruturas condicionais (if-then-else)
-- Funcionamento: Lê a opção através de readLn. Se estiver contida no intervalo válido de 1 é o limite, retorna o valor.
-- Caso contrário, exibe mensagem de erro e chama a si mesma recursivamente para nova tentativa
lerOpcao :: String -> Int -> IO Int
lerOpcao msg limite = do
  putStr msg
  opcao <- readLn
  if opcao >= 1 && opcao <= limite
    then return opcao
    else do
      putStrLn "  Opção inválida. Tente novamente."
      lerOpcao msg limite

-- Captura e validação de opções incluindo retorno
-- Uso de recursão
-- Funcionamento: Comportamento similar a lerOpcao, contudo aceitando o valor 0 (usado no sistema para voltar ou sair)
lerOpcaoOuZero :: String -> Int -> IO Int
lerOpcaoOuZero msg limite = do
  putStr msg
  opcao <- readLn
  if opcao == 0 || (opcao >= 1 && opcao <= limite)
    then return opcao
    else do
      putStrLn "  Opção inválida. Digite um número da lista ou 0 para sair."
      lerOpcaoOuZero msg limite

-- Captura e formatação da data do sistema
-- Funcionamento: Obtém o timestamp atual através de getCurrentTime e o 
-- transforma uma String formatada no padrão "Ano-Mês-Dia" (%Y-%m-%d) via formatTime
dataHoje :: IO String
dataHoje = do
  t <- getCurrentTime
  return (formatTime defaultTimeLocale "%Y-%m-%d" t)


-- TELA 1 — Categorias

-- Exibição do menu principal de categorias
-- Uso de Lazy Evaluation
-- Funcionamento: Imprime o cabeçalho do aplicativo, monta a lista de categorias baseada nos restaurantes atuais e lê a opção
-- Se for 0, encerra o loop; se for válida, redireciona para o menuRestaurantes buscando a categoria correta pelo índice
menuCategorias :: AppState -> IO ()
menuCategorias estado = do
  putStrLn "\n -------------------------------------------------- "
  putStrLn   "|                    Mini-iFood                    |"
  putStrLn   " -------------------------------------------------- "
  putStrLn "\n  O que voce quer comer hoje?\n"
  putStr (exibirCategorias (restaurantes estado))
  putStrLn "  0. Sair do aplicativo"
  putStrLn " -------------------------------------------------- "
  
  opcao <- lerOpcaoOuZero "  Escolha: " (length listaDeCategorias)
  
  if opcao == 0
    then putStrLn "\n  Obrigado por usar o Mini-iFood! Até logo.\n"
    else menuRestaurantes estado (listaDeCategorias !! (opcao - 1))
  where
    listaDeCategorias = categoriasUnicas (restaurantes estado)


-- TELA 2 — Restaurantes da categoria

-- Exibição e seleção de restaurantes filtrados
-- Uso de Lazy Evaluation e composição implícita de estados
-- Funcionamento: Filtra e exibe os restaurantes pertencentes à categoria selecionada. 
-- Se o usuário digitar 0, retorna ao menuCategorias. 
-- Caso selecione um restaurante válido, avança para menuCardapio
menuRestaurantes :: AppState -> String -> IO ()
menuRestaurantes estado categoriaEscolhida = do
  putStrLn ("\n  --- " ++ categoriaEscolhida ++ " ---\n")
  putStr (exibirRestaurantes (restaurantes estado) categoriaEscolhida)
  putStrLn " -------------------------------------------------- "
  putStrLn "  0. Voltar"
  
  opcao <- lerOpcaoOuZero "  Escolha o restaurante: " (length rests)
  
  if opcao == 0
    then menuCategorias estado
    else menuCardapio estado (nomeRest (rests !! (opcao - 1))) []
  where
    rests = restaurantesPorCategoria (restaurantes estado) categoriaEscolhida

-- TELA 3 — Cardápio + adição de itens

-- Exibição do cardápio e controle de adição de itens ao carrinho
-- Conversão de tipos com read
-- Funcionamento: Mostra os pratos disponíveis do restaurante atual. Ao digitar 0, 
-- valida se o carrinho possui itens: se vazio, reinicia a tela; se preenchido, avança para menuCarrinho. 
-- Caso selecione um prato válido, solicita a quantidade e chama a função adicionarItem
menuCardapio :: AppState -> String -> [(Int, Float)] -> IO ()
menuCardapio estado rest itensAtuais = do
  putStr (exibirCardapio rest pratos)
  putStrLn "  0. Fechar pedido e ir ao carrinho"
  putStrLn " -------------------------------------------------- "
  
  opcao <- lerOpcaoOuZero "  Escolha um prato: " (length pratos)
  qtdStr <- if opcao /= 0 then prompt "  Quantidade: " else return "0"
  let qtd = read qtdStr :: Float

  if opcao == 0 && null itensAtuais
    then do
      putStrLn "\n  Carrinho vazio! Adicione pelo menos um item."
      menuCardapio estado rest itensAtuais
    else if opcao == 0
      then menuCarrinho estado rest itensAtuais
    else if qtd >= 1
      then menuCardapio estado rest (adicionarItem itensAtuais opcao qtd)
    else do
      putStrLn "  Quantidade inválida."
      menuCardapio estado rest itensAtuais

  where
    pratos = pratosDoRestaurante (cardapio estado) rest

-- Função para inserção ou atualização de itens no carrinho
-- Uso de casamento de padrões, padrão cabeça/cauda (x:xs) e guardas
-- Funcionamento: Se a lista estiver vazia (caso base), cria um novo elemento.
-- Se a cabeça da lista possuir o mesmo índice (idx) procurado, reconstrói a tupla incrementando a quantidade acumulada.
-- Caso contrário, mantém a cabeça intacta e chama a si mesma recursivamente para a cauda
adicionarItem :: [(Int, Float)] -> Int -> Float -> [(Int, Float)]
adicionarItem [] idx qtd = [(idx, qtd)]
adicionarItem ((i, q):rest) idx qtd
  | i == idx  = (i, q + qtd) : rest
  | otherwise = (i, q) : adicionarItem rest idx qtd


-- TELA 4 — Carrinho

-- Exibição e operação das opções do carrinho de compras
-- Captura uma opção numérica de 1 a 3 que encaminha para: (1) Checkout do 
-- pedido, (2) Retorno ao menuCardapio para adicionar mais itens ou (3) Cancelamento total retornando à raiz
menuCarrinho :: AppState -> String -> [(Int, Float)] -> IO ()
menuCarrinho estado rest itens = do
  putStr (exibirCarrinho (rest, itens) pratos)
  putStrLn " -------------------------------------------------- "
  putStrLn "\n  1. Finalizar pedido"
  putStrLn   "  2. Adicionar mais itens"
  putStrLn   "  3. Cancelar e voltar ao inicio"
  putStrLn " -------------------------------------------------- "
  
  opcao <- lerOpcao "  Escolha: " 3
  
  if opcao == 1
    then checkout estado (rest, itens)
    else if opcao == 2
      then menuCardapio estado rest itens
      else menuCategorias estado
  where
    pratos = pratosDoRestaurante (cardapio estado) rest

-- TELA 5 — Checkout (bairro -> endereço -> cupom -> pagamento -> confirmar)

-- Fechamento de compras
-- Uso de repasse de Estado (AppState) e Escopo Léxico (where)
-- Funcionamento: Executa sequencialmente as etapas de frete por bairro, endereço, 
-- cupom de desconto e escolha de pagamento.
-- Computa os totais extraindo os dados diretamente das listas nativas e 
-- solicita confirmação do pedido

checkout :: AppState -> (String, [(Int, Float)]) -> IO ()
checkout estado (rest, itens) = do
  putStrLn "\n  --- Entrega ---\n"
  (frete, bairro) <- etapaBairro taxas
  endereco        <- prompt "  Digite seu endereço (rua e número): "
  putStrLn ("  Frete para " ++ bairro ++ ": R$ " ++ formatFloat frete)

  putStrLn "\n  --- Cupom ---\n"
  desconto <- etapaCupom (cupons estado) subtotal 

  putStrLn "\n  --- Pagamento ---\n"
  tipoPag <- etapaPagamento

  exibirResumoFinal pratos (rest, itens) subtotal frete desconto tipoPag (calcularTotal subtotal frete desconto tipoPag) bairro endereco
  checkoutReconfirmar estado (rest, itens) pratos subtotal frete desconto tipoPag bairro endereco

  where
    pratos   = pratosDoRestaurante (cardapio estado) rest
    subtotal = calcularSubtotal (rest, itens) (cardapio estado)
    taxas    = buscaTaxas rest (taxacao estado)

-- Validação da confirmação final e execução do pedido
-- Uso de estruturas condicionais (if-then-else)
-- Funcionamento: Analisa a String de resposta obtida do terminal. 
-- Se o caractere digitado for "S" ou "s", valida o sucesso da operação, 
-- emitindo a mensagem de pedido realizado. Caso seja "N" ou "n", 
-- exibe uma mensagem de pedido cancelado e retorna a menuCategorias.
-- Caso seja inserido qualquer outro valor, é exibida uma mensagem de opção inválida 
-- e a função checkoutReconfirmar é chamada novamente. 
checkoutReconfirmar :: AppState -> (String, [(Int, Float)]) -> [a] -> Float -> Float -> Float -> TipoPagamento -> String -> String -> IO ()
checkoutReconfirmar estado (rest, itens) pratos subtotal frete desconto tipoPag bairro endereco = do
  resp <- prompt "\n  Confirmar pedido? (s/n): "
  
  if resp == "S" || resp == "s"
    then do
      putStrLn "\n  Pedido realizado com sucesso!"
      putStrLn   "  Aguarde seu delivery!\n"
      menuCategorias estado
  else if resp == "N" || resp == "n"
    then do
      putStrLn "\n  Pedido cancelado."
      menuCategorias estado
  else do
    putStrLn "Opção inválida! Por favor, digite 's' para sim ou 'n' para nao."
    checkoutReconfirmar estado (rest, itens) pratos subtotal frete desconto tipoPag bairro endereco

-- Identificação de taxas por restaurante
-- Uso de casamento de padrões, padrão cabeça/cauda (x:xs) e guardas
-- Funcionamento: Varre a lista e se encontrar a chave correspondente ao nome do 
-- restaurante, retorna a lista de taxas vinculada. Caso contrário, 
-- segue recursivamente inspecionando o resto da lista até o esgotamento (caso base, retorna vazio)
buscaTaxas :: String -> [(String, [a])] -> [a]
buscaTaxas _ [] = []
buscaTaxas nomeBuscado ((nome, ts):resto)
  | nomeBuscado == nome = ts
  | otherwise           = buscaTaxas nomeBuscado resto


-- Etapas do Checkout

-- Seleção de frete e localidade de entrega
-- Uso de casamento de padrões
-- Funcionamento: Se a lista de taxas do restaurante vier vazia, assume entrega gratuita
-- Caso contrário, aciona a listagem de bairros, lê a entrada do usuário e retorna a tupla escolhida
etapaBairro :: [(String, Float)] -> IO (Float, String)
etapaBairro [] = do
  putStrLn "  Entrega gratuita!"
  return (0.0, "Centro")
etapaBairro taxas = do
  putStrLn "  Selecione seu bairro:\n"
  imprimeBairros 1 taxas
  putStrLn " -------------------------------------------------- "
  opcao <- lerOpcao "  Bairro: " (length taxas)
  let (bairro, taxa) = taxas !! (opcao - 1)
  return (taxa, bairro)

-- Impressão recursiva de bairros enumerados
-- Uso de recursão e casamento de padrões
-- Funcionamento: Caso base para lista vazia cessa a execução (return ()).
-- Caso contenha elementos, desestrutura a primeira tupla pegando apenas a String do bairro,
-- imprime essa string pelo índice auto-incrementado 'i', e chama a si mesma para o resto da lista com (i + 1)
imprimeBairros :: Int -> [(String, Float)] -> IO ()
imprimeBairros _ [] = return ()
imprimeBairros i ((bairro, _):resto) = do
  putStrLn ("  " ++ show i ++ ". " ++ bairro)
  imprimeBairros (i + 1) resto

-- Leitura, processamento e aplicação de cupons promocionais
-- Uso de Lazy Evaluation
-- Funcionamento: Captura o código digitado. Se for vazio, ignora e retorna 0.0. 
-- Caso contrário, obtém a data atual via dataHoje e faz o encadeamento das funções de verificação e cálculo de desconto 
etapaCupom :: ListaCupons -> Float -> IO Float
etapaCupom listC subtotal = do
  putStrLn "  Digite o codigo do cupom (ou Enter para pular):\n"
  codigo <- prompt "  Cupom: "
  
  if codigo == ""
    then do
      putStrLn "  Sem cupom aplicado."
      return 0.0
    else do
      hoje <- dataHoje
      imprimeDesconto (aplicarDesconto (verificarCupom codigo subtotal hoje listC) subtotal)

-- Exibição do feedback de aplicação de cupom promocional
-- Uso de estruturas condicionais (if-then-else) e efeitos colaterais (IO)
-- Funcionamento: Avalia o valor do desconto. Se for maior que zero, imprime uma mensagem confirmando o valor do desconto
-- Caso contrário, emite um aviso de cupom inválido, expirado ou de valor mínimo não atingido. 
imprimeDesconto :: Float -> IO Float
imprimeDesconto desconto = do
  if desconto > 0.0
    then putStrLn ("  Desconto aplicado: R$ " ++ formatFloat desconto)
    else putStrLn "  Cupom invalido, expirado ou valor mínimo não atingido."
    
  return desconto

-- Seleção da forma de pagamento
-- Funcionamento: Exibe na tela as opções de pagamento disponíveis no sistema e 
-- Invoca a função lerOpcao limitando a 5 alternativas e submete o inteiro escolhido à função convertePagamento
etapaPagamento :: IO TipoPagamento
etapaPagamento = do
  putStrLn "  Forma de pagamento:\n"
  putStrLn "  1. Pix (sem acrescimo)"
  putStrLn "  2. Crédito a vista (+3%)"
  putStrLn "  3. Débito (+1%)"
  putStrLn " -------------------------------------------------- "
  opcao <- lerOpcao "  Pagamento: " 3
  return (convertePagamento opcao)

-- Tradução de inteiros para o Tipo de Dado Algébrico de pagamento
-- Uso de casamento de padrões
-- Funcionamento: Associa o número recebido da entrada padrão diretamente 
-- para o construtor correto do tipo TipoPagamento 
convertePagamento :: Int -> TipoPagamento
convertePagamento 1 = Pix
convertePagamento 2 = CreditoVista
convertePagamento 3 = Debito

--------------------------------------------------------------------------------
-- Resumo final
--------------------------------------------------------------------------------

-- Impressão de fechamento da compra
-- Uso de casamento de padrões e blocos condicionais
-- Funcionamento: Imprime o nome do restaurante, itens comprados, subtotal e taxas.
-- Aplica uma guarda condicional para exibir a linha de desconto apenas se o valor obtido for maior que zero
exibirResumoFinal :: [(String, Float)] -> (String, [(Int, Float)]) -> Float -> Float -> Float -> TipoPagamento -> Float -> String -> String -> IO ()
exibirResumoFinal pratos (rest, itens) subtotal frete desconto tipoPag total bairro endereco = do
  putStrLn "\n ------------------------------ "
  putStrLn   "|       RESUMO DO PEDIDO       |"
  putStrLn   " ------------------------------ "
  putStrLn ("\n  Restaurante: " ++ rest)
  putStrLn   "\n  Itens:"
  imprimeItensResumo pratos itens
  putStrLn " -------------------------------------------------- "
  putStrLn ("  Subtotal:          R$ " ++ formatFloat subtotal)
  putStrLn ("  Frete:             R$ " ++ formatFloat frete)
  if desconto > 0
    then putStrLn ("  Desconto (cupom):- R$ " ++ formatFloat desconto)
    else return ()
  putStrLn ("  Forma de pag.:     " ++ descricaoPag tipoPag)
  putStrLn " -------------------------------------------------- "
  putStrLn ("  TOTAL:             R$ " ++ formatFloat total)
  putStrLn " -------------------------------------------------- "
  putStrLn ("  Endereço: " ++ bairro ++ " " ++ endereco)

-- Iteração recursiva para impressão de pratos selecionados
-- Uso de casamento de padrões e padrão cabeça/cauda (x:xs)
-- Funcionamento: Para cada tupla de item (índice, quantidade) na lista, indica a
-- formatação para exibirItemResumo e faz a chamada recursiva com a cauda da lista
imprimeItensResumo :: [(String, Float)] -> [(Int, Float)] -> IO ()
imprimeItensResumo _ [] = return ()
imprimeItensResumo pratos (item:resto) = do
  exibirItemResumo pratos item
  imprimeItensResumo pratos resto

-- Formatação individual de linhas de compra e cálculo parcial de preços
-- Uso da Cláusula local 'where'
-- Funcionamento: Acessa o prato específico do cardápio, arredonda a quantidade para inteiro, 
-- calcula o preço multiplicando(qtd * val) e o apresenta em formato monetário 
exibirItemResumo :: [(String, Float)] -> (Int, Float) -> IO ()
exibirItemResumo pratos (idx, qtd) = do
  putStrLn ("  " ++ show (round qtd :: Int) ++ "x " ++ nome ++ " = R$ " ++ formatFloat (qtd * val))
  where
    (nome, val) = pratos !! (idx - 1)

-- Tradução do tipo de pagamento para String com descrição de acréscimo
-- Uso de casamento de padrões
-- Funcionamento: Avalia a estrutura do tipo TipoPagamento e expõe a respectiva taxa correspondente na string de saída
descricaoPag :: TipoPagamento -> String
descricaoPag Pix = "Pix (sem acrescimo)"
descricaoPag CreditoVista = "Crédito a vista (+3%)"
descricaoPag Debito = "Débito (+1%)"