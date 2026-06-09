module Types where

import qualified Data.Map as Map

type NomeRestaurante = String
type Prato = String
type Preco = Double
type Bairro = String
type CodigoCupom = String


data TipoDesconto = Porcentagem | ValorFixo | PorcentagemFrete | ValorFrete
    deriving (Show, Eq)

data Cupom = Cupom {
    tipo        :: TipoDesconto,
    valorCupom  :: Double,
    dataLimite  :: String,
    valorMinimo :: Double
} deriving (Show, Eq)


type Cardapio = Map.Map NomeRestaurante [(Prato, Preco)]
type Taxacao  = Map.Map NomeRestaurante [(Bairro, Preco)]
type Descontos = Map.Map CodigoCupom Cupom


type ItemCarrinho = (Int, Int)
type Carrinho     = (NomeRestaurante, [ItemCarrinho])


data AppState = AppState {
    cardapioGeral  :: Cardapio,
    taxacaoGeral   :: Taxacao,
    cuponsGeral    :: Descontos,
    carrinhoAtual  :: Carrinho
} deriving (Show)