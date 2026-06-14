-- Arquivo responsável pela leitura dos arquivos de dados do sistema (presentes na pasta data);
-- Cada função lê um arquivo.txt e converte o conteúdo para o tipo correspondente
-- definido em Types.hs, disponibilizando os dados para uso em AppState.

module FileIO
  ( loadRestaurantes
  , loadCardapio
  , loadTaxacao
  , loadCupons
  ) where

import Types

-- FUNÇÃO LOADRESTAURANTES
-- Função loadRestaurantes é responsavel por ler o arquivo de restaurantes (restaurantes.txt) e devolver uma lista de Restaurante.
-- A função readFile le o conteúdo do arquivo como texto, e o read converte esse texto diretamente para o tipo 
-- [Restaurante] através do deriving Read definido na estrutura de Restaurante em Types.hs;

loadRestaurantes :: FilePath -> IO [Restaurante]
loadRestaurantes path = do
  conteudo <- readFile path
  return (read conteudo :: [Restaurante])


-- FUNÇÃO LOADCARDAPIO
-- Função loadCardapio é responsavel por ler o arquivo de cardápios (cardapios.txt) e devolver a representação Cardapio
-- (definida em Types.hs);
-- A função readFile lê o conteúdo do arquivo como texto, e o read converte
-- esse texto para a lista de tuplas correspondente ao tipo Cardapio.

loadCardapio :: FilePath -> IO Cardapio
loadCardapio path = do
  conteudo <- readFile path
  return (read conteudo :: [(String, [(String, Float)])])


-- FUNÇÃO LOADTAXACAO
-- Função loadTaxacao é responsavel por ler o arquivo de taxas (taxas.txt) de entrega e devolver a representação Taxacao
-- (definida em Types.hs);
-- A função readFile lê o conteúdo do arquivo como texto, e o read converte
-- esse texto para a lista de tuplas correspondente ao tipo Taxacao.

loadTaxacao :: FilePath -> IO Taxacao
loadTaxacao path = do
  conteudo <- readFile path
  return (read conteudo :: [(String, [(String, Float)])])


-- FUNÇÃO LOADCUPONS
-- Função loadCupons é responsavel por ler o arquivo de cupons (cupons.txt) e devolver a representação ListaCupons
-- (definida em Types.hs);
-- A função readFile lê o conteúdo do arquivo como texto, e o read converte
-- esse texto para a lista de tuplas correspondente ao tipo ListaCupons.
-- O tipo Cupom possui deriving Read, o que permite que o read converta
-- automaticamente os dados numéricos e de texto para os campos do Cupom.

loadCupons :: FilePath -> IO ListaCupons
loadCupons path = do
  conteudo <- readFile path
  return (read conteudo :: [(String, Cupom)])