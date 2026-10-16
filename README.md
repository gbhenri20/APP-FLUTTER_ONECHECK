# One Check — App Flutter

Aplicativo mobile (Flutter/Dart) para vistorias imobiliárias de entrada e saída, integrado à **API REST One Check** existente (Python/FastAPI). Interface em português brasileiro, tema escuro Material Design 3, autenticação JWT + MFA (TOTP).

## Pré-requisitos

- Flutter SDK **3.35+** (Dart 3.9+)
- Android Studio / Xcode (para emuladores nativos) **ou** Chrome (web)
- API One Check em execução (ver pasta da API ou Docker)

## Configuração da URL da API

Edite um único arquivo:

```json
// assets/env/app_config.json
{
  "environment": "development",
  "apiBaseUrl": "http://127.0.0.1:8765",
  "apiPrefix": "/api/v1",
  ...
}
```

| Ambiente | Exemplo `apiBaseUrl` |
|----------|----------------------|
| Desenvolvimento local | `http://127.0.0.1:8765` |
| Emulador Android → host | `http://10.0.2.2:8765` |
| Dispositivo físico | IP da máquina na LAN |
| Produção/Render | URL HTTPS pública da API |

Modelo sem segredos: `assets/env/app_config.example.json`.

## Instalação e execução

```bash
flutter pub get
flutter analyze
flutter test

# Web (demonstração)
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 43125

# Android
flutter run -d android
```

### Subir a API local (referência)

```bash
cd caminho/da/api
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8765
```

Documentação Swagger: `http://127.0.0.1:8765/docs`

## Contas de demonstração (seed da API)

| Perfil | E-mail | Senha | MFA |
|--------|--------|-------|-----|
| Admin | `admin@onecheck.local` | `admin123` | Sim (TOTP) |
| Gestor | `gestor@onecheck.local` | `gestor123` | Sim |
| Vistoriador | `vistoriador@onecheck.local` | `vistor123` | Sim |
| Locatário | `locatario@onecheck.local` | `locat123` | Não |

Segredo TOTP do seed (apenas ambiente de desenvolvimento): `JBSWY3DPEHPK3PXP`  
(adicione no Google Authenticator / authenticator TOTP para gerar o código de 6 dígitos.)

## Arquitetura

```
lib/
  app/          # tema, router, providers
  core/         # config, Dio, secure storage, Hive, widgets
  features/
    auth/       # login, MFA, setup, sessão
    agenda/     # agenda do vistoriador
    checklist/  # preenchimento, fotos, revisão, envio
    vistoria/   # visão locatário
    ocorrencias/
    perfil/
    logs/       # histórico local de operações
```

**Estado:** Riverpod (DI + async, uma única abordagem).  
**HTTP:** Dio com interceptor de Bearer, refresh com lock e tratamento de erros.  
**Segredos:** `flutter_secure_storage` (nunca SharedPreferences).  
**Offline:** Hive (rascunhos, fila de sync, log local).

## Fluxos principais

1. Login → MFA ou setup MFA → tokens seguros
2. Vistoriador: agenda (pendentes/enviadas) → checklist por cômodo → fotos → revisão → `PATCH .../submeter`
3. Locatário: listar vistorias → aceitar / rejeitar com motivo → ocorrências
4. Admin/Gestor: dashboard agregado

## Documentação adicional

- [Diagnóstico da API e limitações](docs/DIAGNOSTICO_API.md)
- [README original da API](docs/api-reference/README.md)

## Testes e qualidade

```bash
flutter analyze   # esperado: No issues found
flutter test
```

Cobertura crítica: login/MFA, modelos de checklist, renovação de sessão (mock HTTP).

## Observações importantes

- O app **não** reimplementa TOTP localmente; a validação é sempre da API.
- Não há endpoint global de agenda: a lista é agregada via contratos/checklists.
- Vistorias de `encerramento` ficam ocultas na agenda principal do vistoriador.
- Após submissão (`pendente_aceite` / `aceito` / `rejeitado`), a API bloqueia edição.
