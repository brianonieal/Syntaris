gh api repos/OWNER/REPO/contents/foundation/RESEARCH_AGENDA.md \
  --method PUT \
  --field message="add RESEARCH_AGENDA" \
  --field content="$(base64 -w0 'D:/Blueprint/foundation/RESEARCH_AGENDA.md')"
