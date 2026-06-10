module Types where

import qualified Data.Map.Strict as Map

-- ---------------------------------------------------------------------------
-- Tipos de dados principais
-- ---------------------------------------------------------------------------

data Restaurante = Restaurante
  { nomeRest      :: String
  , categoriaRest :: String
  } deriving (Show, Eq, Read)

-- Cardapio: restaurante -> lista de (prato, valor)
type Cardapio = Map.Map String [(String, Float)]

-- Taxas: restaurante -> lista de (bairro, taxa)
type Taxacao = Map.Map String [(String, Float)]

-- Cupom: codigo -> (tipo, valor, dataLimite, valorMinimo)
type MapCupons = Map.Map String Cupom

data Cupom = Cupom
  { cupomValor      :: Float
  , cupomDataLimite :: String   -- formato "YYYY-MM-DD"
  , cupomValorMin   :: Float
  } deriving (Show, Eq, Read)

data TipoDesconto
  = Porcentagem       -- desconto % sobre o subtotal
  | ValorFixo         -- desconto R$ fixo sobre o subtotal
  | ValorFrete        -- desconto R$ fixo sobre o frete (999 = frete grátis)
  | PorcentagemFrete  -- desconto % sobre o frete
  deriving (Show, Eq, Read)

-- Carrinho: (nomeRestaurante, [(indicePrato 1-based, quantidade)])
type Carrinho = (String, [(Int, Float)])

-- Tipo de pagamento
data TipoPagamento
  = Pix
  | CreditoVista
  | CreditoParcelado Int   -- numero de parcelas
  deriving (Show, Eq, Read)

-- Estado global do app (carregado uma vez no Main)
data AppState = AppState
  { restaurantes :: [Restaurante]
  , cardapio     :: Cardapio
  , taxacao      :: Taxacao
  , cupons       :: MapCupons
  }