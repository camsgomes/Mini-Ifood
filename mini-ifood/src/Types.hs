-- Arquivo contendo a definição de todos os tipos (modelagem do que seria entidades em outras linguagens)
-- Presente no sistema.

module Types where


------------------------- TIPOS - SIMULAÇÃO DE ENTIDADES ----------------------------

-- TIPO RESTAURANTE
-- Representação da "entidade" Restaurante no sistema;
-- Campo nomeRest: Nome do restaurante (ex: "SushiLom");
-- Campo categoriaRest: Categoria que o restaurante faz parte 
-- (ex: "Comida japonesa").

data Restaurante = Restaurante
  { nomeRest      :: String
  , categoriaRest :: String
  } deriving (Show, Eq, Read)


-- TIPO CUPOM
-- Representação da "entidade" Cupom com determinado desconto associado a ele 
-- a partir do seu tipo, além de informações extras associadas a esse tipo;
-- As informações (valores reais) associadas a representação do tipoDesconto 
-- são extraídas do arquivo cupons.txt  a partir da ações em FileIo.hs;
-- Campo cupomTipo: Tipo do desconto (ex: ValorFrete);
-- Campo cupomValor: Valor real ou porcentagem de quanto será o desconto 
-- sob um valor total;
-- Campo cupomDataLimite: Data de validade para uso do cupom;
-- Campo cupomValorMin: Valor mínimo do pedido para o cupom ser usado.

data Cupom = Cupom
  { cupomTipo       :: TipoDesconto
  , cupomValor      :: Float
  , cupomDataLimite :: String  -- formato "YYYY-MM-DD"
  , cupomValorMin   :: Float
  } deriving (Show, Eq, Read)


-- TIPO TIPODESCONTO
-- Representação da "entidade" TipoDesconto que define como e onde o desconto será aplicado;
-- Campo Porcentagem:      desconto eh uma porcentagem no valor dos itens;
-- Campo ValorFixo:        o desconto eh um valor fixo em reais sob o valor dos itens;
-- Campo ValorFrete:       o desconto eh um valor fixo em reais sob o frete;
-- Campo PorcentagemFrete: o desconto eh uma porcentagem sob o frete.

data TipoDesconto
  = Porcentagem
  | ValorFixo
  | ValorFrete
  | PorcentagemFrete
  deriving (Show, Eq, Read)


-- TipoPagamento
-- Representação da "entidade" TipoPagamento de define a forma como o usuario fara o pagamento, 
-- considerando acrescimo no valor dependendo da escolha do tipo;
-- Campo Pix: Sem acrescimo no valor total;
-- Campo CreditoVista: Acrescimo de 3% no valor total;
-- Campo CreditoParcelado: Acrescimo de N * 2.5% no valor total, sendo N o numero de parcelas.

data TipoPagamento
  = Pix
  | CreditoVista
  | CreditoParcelado Int
  deriving (Show, Eq, Read)



----------------------------- REPRESENTAÇÕES - LISTAS --------------------------

-- REPRESENTAÇÃO CARDAPIO
-- Lista Cardapio com tuplas contendo o nome do restaurante com sua lista de pratos disponíveis 
-- e os preços associados a eles;
-- Idea estrutural: [(nomeRest, [(nomePrato1, precoPrato1), (nomePrato2, precoPrato2)])];
-- Exemplo: [("SushiLom", [("Temaki", 24.75), ("Yaksoba", 37.00)])];
-- As informações do nome do prato com o preço associado a ele são extraídos do arquivo cardapios.txt
-- e manipulados em FileIo.hs.

type Cardapio = [(String, [(String, Float)])]


-- REPRESENTAÇÃO TAXAÇÃO
-- Lista Taxacao com tuplas contendo nome do restaurante com a lista de taxas (par nome do bairro e o 
-- valor do frete) selecionados pelo usuario para a entrega.
-- Ideia estrutural: [(nomeRest, [(nomeBairro1, valorFrete1), (nomeBairro2, valorFrete2)])];
-- Exemplo: [("SushiLom", [("Centro", 5.00), ("Prata", 7.50)])].
-- As informações dos pares de taxa e restaurante associado a elas são extraídas do arquivo taxas.txt e manipuladas em FileIo.hs;

type Taxacao = [(String, [(String, Float)])]


-- REPRESENTAÇÃO MAPACUPONS
-- Lista MapCupon com tuplas contendo chave (codigoCupom) e Cupom.
-- Ideia estrutural: [(codigoCupom1, Cupom1 {...}), (codigoCupom2, Cupom2 {...})]
-- Exemplo: [("BEMVINDO", Cupom {...}), ("FRETE0", Cupom {...})]
-- As informações do codigo do cupom são extraídas do arquivo cupons.txt e o Cupom da "entidade" definida anteriormente.

type MapCupons = [(String, Cupom)]


-- REPRESENTAÇÃO CARRINHO
-- Lista Carrinho com tupla contedo nome do restaurante com a lista de todos os itens selecionados (prato e quantidade desse prato) pelo usuario para compra;
-- Ideia estrutural: (nomeRest, [(indicePrato1, quantidade), (indicePrato2, quantidade2)]), sendo o indicePrato apresentado via terminal para o usuario escolher 
-- e a quantidade também escolhida dessa maneira por ele;
-- Exemplo: ("SushiLom", [(1, 2), (3, 1)]), sinifica 2 unidades do prato 1 e 1 unidade do prato 3.

type Carrinho = (String, [(Int, Int)])



-------------------------- REPRESENTAÇÃO DE UM "REPOSITÓRIO CENTRAL" PARA USO DAS "ENTIDADES" E LISTAS DO SISTEMA -----------------------------
-- TIPO APPSTATE
-- Representação da "entidade" AppSate que atua como o estado global do programa, carregado uma unica vez no Main a partir dos arquivos de dados 
-- e repassado para todas as telas do sistema;
-- Campo restuarntes: Lista de todos os restaurantes cadastrados no sistema, extraída do arquivo restaurantes.txt;
-- Campo cardapio: Lista com os cardápios de todos os restaurantes, extraída do arquivo cardapios.txt;
-- Campo taxacao: Lista com as taxas de entrega de todos os restaurantes por bairro, extraída do arquivo taxas.txt;
-- Campo cupons: Lista com todos os cupons de desconto disponíveis no sistema, extraída do arquivo cupons.txt;

data AppState = AppState
  { restaurantes :: [Restaurante]
  , cardapio     :: Cardapio
  , taxacao      :: Taxacao
  , cupons       :: MapCupons
  }