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
| `⌘E` | mostrar/ocultar o épico ou a tarefa-pai nos cards |
| `⌘?` | guia do app |

## O épico nos cards

Os cards podem mostrar uma linha com o card pai — o épico, ou a tarefa mãe quando o card
é uma subtask. Ela entra **desligada**: no quadro ocupa uma das três linhas úteis do card
e costuma repetir o mesmo épico card a card, enquanto a daily gira em torno do que a
pessoa fez e vai fazer. `⌘E` liga e desliga, e a escolha fica salva.

## Primeira abertura

Quem abre o app sem nada configurado cai numa folha de quatro passos que não dá para
fechar antes do fim: conta do Jira (com link para gerar o API token), projetos, time e
um guia de três telas sobre como a rodada funciona. O passo da conta só avança depois
que o Jira aceita a credencial — errar ali deixaria as duas telas seguintes vazias sem
dizer por quê, e a mensagem separa token inválido de acesso negado pelo SSO.

Quem abre a página de criar o token pelo próprio setup não precisa colar: enquanto essa
página está aberta, o app observa a área de transferência e, assim que aparece algo com
forma de API token da Atlassian, preenche o campo e confere sozinho. Só vale para o que
foi copiado depois de abrir a página, e só com o campo vazio.

O passo do time explica a regra que costuma pegar o time de surpresa: a lista é montada
a partir de quem está como **responsável por algum card em aberto nos projetos
selecionados**. Quem não tem card atribuído não aparece — para incluir alguém é preciso
adicionar o projeto onde essa pessoa tem cards, ou atribuir um card a ela no Jira.

O guia continua acessível depois, em **Ajuda › Guia do AsaasDaily** (`⌘?`), e o setup
inteiro pode ser refeito em **Ajuda › Refazer configuração…**.

## Configuração

Em **Preferências** (`⌘,`): e-mail e API token do Jira (gerado em `id.atlassian.com`),
os projetos que entram na daily e quem participa. São os mesmos controles do setup
inicial. O token fica no Keychain.

Quem usava o app anterior em .NET MAUI tem a configuração importada automaticamente na
primeira execução — credenciais, projetos e apelidos do time. Nesse caso o setup não
aparece: o app já tem tudo de que precisa.

## Assinatura

O projeto aponta para um certificado Apple Development pelo hash, em
`CODE_SIGN_IDENTITY`. Isso é o que mantém a identidade do app estável entre builds —
com assinatura ad-hoc, o macOS trata cada build como um app diferente e o Keychain
volta a pedir autorização para ler o token a cada abertura.

O efeito colateral é que o projeto só compila na máquina que tem esse certificado.
Quando outra pessoa for compilar, troque por assinatura automática
(`CODE_SIGN_STYLE = Automatic` com o `DEVELOPMENT_TEAM` dela) ou pelo hash do
certificado dela.

## Distribuição

| Script | O que faz |
|---|---|
| `scripts/install.sh` | compila em Release e substitui o app em `/Applications` |
| `scripts/dist.sh` | gera `dist/AsaasDaily-<versão>.zip` |
| `scripts/build-dmg.sh` | gera `dist/AsaasDaily-<versão>.dmg`, com o app e o atalho de Aplicativos numa janela desenhada |

O fundo da janela do `.dmg` é gerado por `design/dmg/DmgBackground.swift`, com a mesma
paleta e a mesma roda do ícone. Na primeira execução o macOS pede para o Terminal
controlar o Finder — é o Finder que grava o layout da janela do volume.

Com assinatura Apple Development (não Developer ID), quem receber o `.dmg` ainda vê o
aviso do Gatekeeper na primeira abertura.

## Requisitos

- macOS 15
- Xcode 26 para compilar
- Conta no Jira com acesso aos boards dos projetos

## Estrutura

```
AsaasDaily/
├── Jira/        cliente da API: boards, issues, paginação, Keychain
├── Daily/       modelo da rodada e as telas
├── Onboarding/  setup de primeira abertura e guia do app
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
