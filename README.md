# MTG Collector (MTGC)

Aplicativo móvel para **simular a abertura de boosters de Magic: The Gathering** e
gerenciar a coleção de cartas obtidas. O usuário compra e abre pacotes (Play e
Collector), revela as cartas com uma animação de "swipe", e cada carta aberta é
registrada na sua coleção no servidor. As cartas, imagens e preços vêm da API
pública da **Scryfall**.

> **Status de entrega:** este README é a documentação mínima exigida pela
> atividade. A tabela de [cobertura dos requisitos](#cobertura-dos-requisitos)
> indica o que já está implementado e o que ainda está pendente.

---

## Problema e solução

- **Problema:** abrir boosters físicos de Magic é caro e o colecionador não tem
  uma forma simples de simular aberturas e acompanhar o valor/coleção resultante.
- **Público-alvo:** jogadores e colecionadores de Magic: The Gathering.
- **Solução:** um app que simula a abertura de boosters usando as probabilidades
  reais de cada slot (ver [`mtgc/docs/mtg-boosters.md`](mtgc/docs/mtg-boosters.md)),
  credita/debita uma carteira virtual conforme o valor das cartas, e persiste a
  coleção do usuário em um backend próprio. A interface se adapta a telas
  dobráveis (Huawei Mate XT), aproveitando múltiplos painéis.

<!-- TODO: link do vídeo de demonstração (problema, solução, etapas, considerações). -->
<!-- TODO: opcional — screenshots/gifs das telas principais. -->

---

## Tecnologias utilizadas

| Camada | Tecnologia |
|---|---|
| App mobile | **Flutter / Dart** |
| Backend | **FastAPI** (Python) |
| Banco de dados | **PostgreSQL** (via `asyncpg`) |
| Autenticação | **JWT** (PyJWT) + senhas com **bcrypt** |
| API externa | **Scryfall** (`https://api.scryfall.com`) |
| Armazenamento local | `shared_preferences`, `flutter_secure_storage` (token JWT) |
| HTTP | pacote `http` |

---

## Arquitetura

```
MTGCollector/
├── mtgc/        # App Flutter (cliente)
│   ├── lib/
│   │   ├── pages/      # Telas: login, menu, seleção, booster, coleção
│   │   ├── services/   # api_client, scryfall, wallet, auth_storage, ...
│   │   ├── models/     # MtgCard, BoosterProduct, CollectionEntry
│   │   └── ui/         # layout_metrics (telas dobráveis), card_detail
│   └── docs/           # Notas sobre boosters e a API Scryfall
└── server/      # API FastAPI + Postgres
    ├── main.py
    └── schema.sql
```

**Fluxo principal:** Login/Cadastro → Menu → Seleção de booster → Abertura e
revelação das cartas → cartas registradas na coleção (servidor) → Coleção em
grade responsiva.

### Telas (navegação)

`AuthGate` decide entre **Login** e **Menu**. A partir do **Menu** o usuário
navega para **Seleção de Booster** → **Booster** (abertura) e para a **Coleção**.
São mais de duas telas com navegação funcional (`Navigator` / `MaterialPageRoute`).

### Backend / Banco de dados

API FastAPI com PostgreSQL. Tabelas `users` e `cards` (ver
[`server/schema.sql`](server/schema.sql)); o schema é aplicado automaticamente na
inicialização. Endpoints:

| Método | Rota | Auth | Descrição |
|---|---|---|---|
| GET | `/health` | — | healthcheck |
| POST | `/auth/register` | — | cadastro, retorna `{token}` |
| POST | `/auth/login` | — | login, retorna `{token}` |
| GET | `/collection` | Bearer | lista a coleção do usuário |
| POST | `/collection/cards` | Bearer | registra cartas abertas |

### API externa (Scryfall)

O app busca o pool de cartas de um set e suas imagens/preços na Scryfall
(`mtgc/lib/services/scryfall.dart`), agregando valor real à simulação de abertura.

---

## Instruções de execução

### Pré-requisitos

- Flutter SDK (canal estável) e um emulador/dispositivo.
- Python 3.12+ e PostgreSQL (ou Docker).

### 1. Backend (`server/`)

```bash
cd server
# Postgres local via Docker (opcional):
docker run -d --name mtgc-pg -e POSTGRES_PASSWORD=pg -p 5432:5432 postgres:16

python -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt          # ou requirements-dev.txt para rodar testes
export DATABASE_URL="postgresql://postgres:pg@localhost:5432/postgres"
export JWT_SECRET="dev-secret"
uvicorn main:app --reload                # sobe em http://localhost:8000
```

Variáveis de ambiente: ver [`server/.env.example`](server/.env.example).
Deploy (Railway) documentado em [`server/README.md`](server/README.md).

### 2. App (`mtgc/`)

```bash
cd mtgc
flutter pub get
flutter run
```

Na tela de **Login**, use **"Configurar servidor"** para apontar a URL do backend
(ex.: `http://10.0.2.2:8000` no emulador Android, ou o domínio do Railway).
Depois cadastre-se / faça login e use o app.

---

## Cobertura dos requisitos

| # | Requisito | Status | Implementação |
|---|---|---|---|
| 1 | App mobile (não web responsivo) | ✅ | App Flutter (`mtgc/`) |
| 2 | Mais de duas telas + navegação | ✅ | Login, Menu, Seleção, Booster, Coleção |
| 3 | Backend funcional | ✅ | FastAPI (`server/`) |
| 4 | Banco de dados | ✅ | PostgreSQL (`users`, `cards`) |
| 5 | API externa | ✅ | Scryfall |
| 6 | Sistema de notificações | ✅ | Notificações locais +5/+10 min após abrir um pack (`NotificationService`) |
| 7 | Compartilhamento | ✅ | Compartilhar imagem + legenda da carta via share nativo (`CardShareService`) |
| 8 | Uso de hardware do device | ⚠️ Fora de escopo | Acordado com o revisor |
| — | Tratamento de erros/carregamentos | ✅ | `ApiException`, spinners, botão "Tentar novamente" |
| — | Interface coerente com a proposta | ✅ | Tema próprio, fluxo de coleção |
| — | Documentação mínima | ✅ | Este README |
| — | Código-fonte em repositório | ✅ | <https://github.com/cucapcosta/MTGC> |
| — | Vídeo/demonstração | ⬜ | <!-- TODO: adicionar link --> |

> **Observação:** os requisitos 6 (notificações) e 7 (compartilhamento) estão
> implementados. O requisito 8 (hardware) foi acordado como fora de escopo com o
> revisor.

---

## Licença

Projeto acadêmico (Atividade Ponderada 4).
