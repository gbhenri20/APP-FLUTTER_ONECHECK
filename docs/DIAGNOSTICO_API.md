# Diagnóstico técnico — One Check API × App Flutter

Fontes analisadas: código em `ISG022-One-Check-API-Python-main` (README, routers, models, schemas, auth, deps) e documentação em `docs/`. O PDF `SistemaOneCheck.pdf` **não estava no upload**; foi usado o PDF de Threat Modeling da disciplina apenas como contexto acadêmico. O contrato oficial é o código da API.

## 1. Arquitetura da API

- **Stack:** FastAPI + SQLAlchemy + JWT (HS256) + TOTP (`pyotp`) + Bcrypt
- **Prefixo:** `/api/v1`
- **Envelope:** `{ "sucesso": bool, "dados": ..., "erro": string? }`
- **Base local padrão:** `http://localhost:8000` (`PUBLIC_BASE_URL`)
- **Uploads:** `multipart/form-data` campo `foto`; servidos em `/api/v1/uploads/{filename}`

## 2. Autenticação e MFA (fluxo real)

1. `POST /auth/login` `{email, senha}`
   - Credenciais inválidas → `sucesso: false`
   - Se role ∈ {admin, gestor, vistoriador} **e** `mfa_enabled` **e** tem `mfa_secret` → `mfa_required` + `temp_token`
   - Se role privilegiada **e** `mfa_enabled` **sem** secret → `mfa_setup_required` + `temp_token`
   - Caso contrário → `access_token` + `refresh_token` + `usuario`
2. `POST /auth/mfa/verify` `{temp_token, codigo}` → tokens finais
3. Setup inicial: `GET /auth/mfa/setup-login?temp_token=` → secret/QR; depois `POST /auth/mfa/activate-login`
4. `POST /auth/refresh` `{refresh_token}` → access + refresh **rotacionados**
5. `POST /auth/logout` (Bearer) + opcional `{refresh_token}`

Access token: ~60 min (configurável). Refresh: ~30 dias. Temp MFA: 10 min.

## 3. Perfis (RBAC)

| Role | MFA | App mobile |
|------|-----|------------|
| `admin` | obrigatório (quando habilitado) | Painel/dashboard, consulta de vistorias |
| `gestor` | idem | Idem operacional |
| `vistoriador` | idem | Agenda, checklist, fotos, submissão |
| `locatario` | opcional | Aceite/rejeição, ocorrências |

A API também menciona role `visualizador` em uma checagem de checklist; não é perfil seed padrão.

## 4. Endpoints usados pelo app

### Auth
- `POST /auth/login`, `/auth/mfa/verify`, `/auth/mfa/setup-login`, `/auth/mfa/activate-login`
- `POST /auth/refresh`, `/auth/logout`
- `GET /usuarios/me`

### Agenda / vistoria
- `GET /contratos` (vistoriador: só contratos com checklist atribuído)
- `GET /contratos/{id}/checklists`
- `GET /contratos/{id}/agendamentos`
- `GET /imoveis/{id}`
- `GET /checklists/{id}` (+ comodos)
- `GET /itens-vistoria`
- `POST/PUT /checklists/{id}/itens[/{iid}]`
- `POST /checklists/{id}/itens/{iid}/fotos` (campo `foto`)
- `DELETE .../fotos/{fid}`
- `PATCH /checklists/{id}/submeter` (exige ≥ 1 item com estado)
- `PATCH .../aceitar`, `.../rejeitar`

### Locatário / ocorrências / admin
- `GET/POST /contratos/{id}/problemas`, `GET /problemas/{id}`
- `GET /dashboard` (admin/gestor)

## 5. Limitações e divergências

1. **Sem `GET /agendamentos` global** — agenda montada agregando contratos + checklists + agendamentos por contrato.
2. **Encerramento:** app oculta `tipo=encerramento` na agenda principal (regra de produto); API ainda permite listar.
3. **Estados de item:** apenas `otimo|bom|regular|ruim`.
4. **Foto:** um item só mantém a foto mais recente (API substitui anteriores).
5. **Mutabilidade:** itens/fotos só em `em_preenchimento`; após `submeter` → `pendente_aceite`.
6. **Seed de teste:** usuários `@onecheck.local` com MFA habilitado compartilham segredo TOTP (ver seed). Locatários sem MFA.
7. O README lista `POST /mfa/setup-login`, mas a implementação é **`GET` com query**.

## 6. Arquitetura Flutter proposta

- **Riverpod** — estado assíncrono e DI sem boilerplate excessivo (escolha única).
- **Dio** + interceptor de Bearer, refresh com lock anti-concorrência, mapeamento de erros.
- **flutter_secure_storage** — tokens/sessão.
- **Hive** — rascunhos, fila de sync e log local de operações.
- Organização **feature-first** (`auth`, `agenda`, `checklist`, `ocorrencias`, `perfil`).

## 7. Plano de implementação

1. Core (config, Dio, storage, theme, router)
2. Auth + MFA + refresh + logout
3. Agenda vistoriador + checklist + fotos + revisão/envio
4. Locatário (aceite/rejeição) + ocorrências
5. Admin/gestor (dashboard)
6. Offline/log local + testes + README
