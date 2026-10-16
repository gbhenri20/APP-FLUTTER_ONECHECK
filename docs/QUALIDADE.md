# Qualidade — One Check Flutter

## flutter analyze

```text
Analyzing workspace...
No issues found!
```

## flutter test

```text
All tests passed! (11 tests)
```

Cobertura:

- Roles e serialização de usuário
- Modelos de checklist / regras de edição
- Login inválido, MFA obrigatório, setup MFA, verify OK, MFA inválido (mock Dio)
- Widget: tela de login + validação de formulário

## Integração com API local

- Health: `GET /api/v1/health` → ok
- Login vistoriador → `mfa_required` + `temp_token` (comportamento esperado do seed)
