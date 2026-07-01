# Contributing

Thanks for taking time to improve EteDrop.

## Development Principles

- Keep changes focused and easy to review.
- Prefer existing project patterns over introducing new framework choices.
- Do not commit generated build output unless it is intentionally part of the
  deployment flow.
- Do not commit secrets, signing keys, certificates, or private service config.
- Test the affected package before opening a pull request.

## Common Checks

Flutter client:

```bash
cd fast_send_flutter
flutter pub get
flutter analyze
flutter test
```

Nest server:

```bash
cd fast_send_server
npm ci
npm run lint
npm test
```

Share page:

```bash
cd share-page-app
npm ci
npm run build
```

Website:

```bash
cd website
npm ci
npm run typecheck
npm run build
```

Run the checks that match your change. If a check cannot be run locally, mention
that in the pull request.
