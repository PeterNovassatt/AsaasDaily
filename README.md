# AsaasDaily

App para Mac que conduz a daily do time: sorteia a ordem de fala a partir do Jira,
mostra o quadro de quem está falando e deixa a reunião andar sem ninguém precisar
abrir o board e procurar card por card.

## Por que existe

A daily trava nas mesmas coisas: alguém esquece de quem já falou, o board fica aberto
numa aba que ninguém acompanha, e os impedimentos só aparecem quando alguém lembra de
mencionar. O AsaasDaily resolve isso lendo o Jira direto — a ordem prioriza quem tem
card em code review ou em progresso, os cards com flag aparecem destacados, e dá para
pular, voltar e recarregar os cards de uma pessoa sem refazer a rodada.

## Como funciona

- **Ordem de fala** — quem tem card em code review entra primeiro, depois quem está
  com algo em progresso; o restante do time entra sorteado. O card que trouxe a pessoa
  para a rodada fica marcado com uma estrela.
- **Lista ou quadro** — a lista rende mais em densidade (quem tem 35 cards agradece);
  o quadro espelha o board do Jira. Alterna na barra de ferramentas.
- **Pai e filho** — se a story e a subtask aparecem para a mesma pessoa, só a folha
  conta; o pai vira contexto dentro do card do filho.
- **Modo apresentação** (`⇧⌘P`) — tela cheia, sem barra lateral, legível de longe.

## Atalhos

| Atalho | Ação |
|---|---|
| `→` | próximo |
| `←` | voltar para quem já falou |
| `⌘K` | pular (manda para o fim da fila) |
| `⌘R` | atualizar os cards de quem está falando |
| `⇧⌘R` | nova rodada |
| `⇧⌘P` | modo apresentação |
| `⌘+` `⌘−` `⌘0` | tamanho do texto |
| `⌘,` | preferências |

## Configuração

Em **Preferências** (`⌘,`): e-mail e API token do Jira (gerado em `id.atlassian.com`),
os projetos que entram na daily e quem participa. O token fica no Keychain.

Quem usava o app anterior em .NET MAUI tem a configuração importada automaticamente na
primeira execução — credenciais, projetos e apelidos do time.

## Assinatura

O projeto aponta para um certificado Apple Development pelo hash, em
`CODE_SIGN_IDENTITY`. Isso é o que mantém a identidade do app estável entre builds —
com assinatura ad-hoc, o macOS trata cada build como um app diferente e o Keychain
volta a pedir autorização para ler o token a cada abertura.

O efeito colateral é que o projeto só compila na máquina que tem esse certificado.
Quando outra pessoa for compilar, troque por assinatura automática
(`CODE_SIGN_STYLE = Automatic` com o `DEVELOPMENT_TEAM` dela) ou pelo hash do
certificado dela.

## Requisitos

- macOS 15
- Xcode 26 para compilar
- Conta no Jira com acesso aos boards dos projetos

## Estrutura

```
AsaasDaily/
├── Jira/        cliente da API: boards, issues, paginação, Keychain
├── Daily/       modelo da rodada e as telas
├── Settings/    preferências e importação da configuração antiga
└── Design/      aparência, escala de texto e cor por status
reference/       código do app MAUI anterior, recuperado por decompilação
```

## Sobre a pasta `reference`

O app anterior (WhoWillTalk, depois DailyDriver) teve o código-fonte perdido. O que está
em `reference/` foi recuperado decompilando o binário que havia sobrado — inclusive os
XAML, que ficam embutidos no assembly. Serve como documentação da regra de negócio:
qual campo do Jira é o "Flagged" nesta instância, como a ordem de fala era montada, e
por que a paginação importa.
