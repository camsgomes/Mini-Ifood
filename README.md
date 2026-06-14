
# Mini-iFood (Haskell)

Um aplicativo de delivery de comida via terminal, desenvolvido inteiramente em **Haskell**. Este projeto foi construído como requisito para a disciplina de **Paradigmas de Linguagens de Programação (PLP)**, aplicando estritamente os conceitos do **Paradigma Funcional**.

## Funcionalidades

- **Navegação Dinâmica:** Filtragem de restaurantes por categoria de comida.
- **Cardápio e Carrinho:** Adição de itens ao carrinho com atualização recursiva de estado.
- **Sistema de Checkout Completo:**
  - Cálculo de frete baseado taxas específicas de bairros por restaurante.
  - Validação de Cupons de Desconto (verificação de valor mínimo e data de validade, aplicado no subtotal (sem frete agregado).
  - Cálculo de acréscimos por forma de pagamento (Pix, Crédito à Vista, Parcelado).
- **Resumo do Pedido:** Exibição de nota fiscal

---

## Arquitetura do Sistema (Módulos)

O sistema foi rigorosamente dividido para respeitar a separação entre **Funções Puras** (Transparência Referencial) e **Efeitos Colaterais** (`IO`), dividido em 4 módulos principais:

### 1. `Types.hs` (Modelagem de Dados)
Define as estruturas imutáveis do sistema usando **Tipos Algébricos de Dados** e **Sinônimos de Tipos**.
- Define estruturas base como `Restaurante`, `Cupom`, `Cardapio` e `Taxacao` (usando Tuplas e `Listas`).
- Utiliza **Uniões Disjuntas** para definir o `TipoPagamento` (ex: `Pix | CreditoVista | CreditoParcelado Int`).

### 2. `FileIO.hs` (Persistência)
Responsável pelo encapsulamento das funções impuras de leitura do disco. Carrega as listas de restaurantes, cardápios, bairros e cupons a partir de arquivos `.txt` e os converte para as estruturas de `Types.hs` através do polimorfismo da função `read`.

### 3. `Logic.hs` (O Coração Funcional)
Módulo **100% puro**. Não possui nenhuma operação de Entrada/Saída (`IO`). Ele recebe dados, processa matematicamente e devolve novos valores.
- **Filtragem e Buscas:** Extração de categorias únicas e filtragem de restaurantes.
- **Cálculo de Carrinho:** Multiplicação pura de quantidades (`Float`) pelos valores dos pratos.
- **Validação de Cupons** Utilização intensiva de **Guardas (`|`)** e **Recursão** para avaliar condições, retornando estados zerados (`Cupom 0.0`) em caso de falha.
- **Formatação de Strings (Polimorfismo):** Foi utilizado a desestruturação de listas de caracteres (`c1:c2:resto`) e funções polimórficas que facilitaram o processo de conversão sem a necessidade de `cast`.

### 4. `UI.hs` (Interface do Usuário)
Gerencia a interação com o terminal e a navegação do usuário.
- Como não há laços de repetição imperativos (`while`/`for`), a permanência do usuário nos menus é feita através de **Recursão** (uma tela chamando a próxima ou a si mesma).
- O estado do carrinho nasce vazio e é repassado adiante a cada adição. O encadeamento do "Checkout" atua como **Expressões Leitoras de Estado**, coletando o frete, o cupom e o pagamento sequencialmente para repassar à função final de fechamento.

---

## Conceitos do Paradigma Funcional Aplicados

Este projeto demonstra o domínio dos seguintes temas abordados em sala de aula:

- **Imutabilidade e *State Threading*:** Nenhuma variável muda de valor no sistema. Quando o usuário adiciona um item ao carrinho, a função não altera a lista original, mas cria uma nova lista e a passa como argumento para a próxima iteração recursiva. Cancelar um pedido apenas descarta o escopo atual, e o coletor de lixo da memória (*Heap*) cuida do resto.
- **Casamento de Padrões:** Usado para extrair cabeças e caudas de listas (`(x:xs)`), extrair dados de Tuplas e evitar o uso da estrutura `case/switch` ao processar formas de pagamentos.
- **Guardas (Guards `|`):** Substituição limpa para condicionais aninhados (`if/then/else`). Utilizado em `Logic.hs` para direcionar o fluxo de busca de dados e contornar erros sem quebrar a execução.
- **Tipagem Forte e Estática:** As definições de assinatura garantem que o compilador bloqueie operações inseguras em tempo de compilação, eliminando o comportamento imprevisível de tipagens fracas.
- **Cláusulas `where` (Escopo Léxico):** Isolamento de lógicas internas e expressões locais para evitar o recálculo de valores repetidos e esconder funções auxiliares da visibilidade global do sistema.

---

## Como Executar o Projeto

**Pré-requisitos:** Ter o GHC (Glasgow Haskell Compiler) e o `cabal` instalados.

1. Clone o repositório.
2. Certifique-se de que os arquivos de dados (ex: `restaurantes.txt`, `cupons.txt`) estão preenchidos corretamente no formato de tuplas nativas do Haskell na raiz do projeto.
3. No terminal, compile e construa o projeto usando o Cabal:
   ```bash
   cabal build
4. No terminal digite para rodar o código
   ```bash
   cabal run
