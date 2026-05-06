# DEPLOYMENT.md - Vite + Express

## PRE-DEPLOY
- [ ] Tests pass (frontend AND backend)
- [ ] Frontend env: VITE_API_URL pointing at backend deploy URL
- [ ] Backend env: DATABASE_URL, JWT_SECRET (rotated if exposed), CORS_ORIGIN

## DEPLOY
Frontend: `npm run build` then deploy `dist/` to Vercel/Netlify
Backend: Push to Render or Railway

## POST-DEPLOY
- [ ] Frontend loads
- [ ] Backend `GET /health` returns 200
- [ ] Auth + critical user path
