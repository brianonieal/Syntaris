# DEPLOYMENT.md - Python CLI distribution

CLIs aren't deployed; they're distributed. The "deploy" gate for a Python CLI is a published package.

## PRE-PUBLISH

- [ ] All tests pass: `pytest`
- [ ] Lint clean: `ruff check .`
- [ ] Type check clean: `mypy .`
- [ ] Version bumped in `pyproject.toml` and `__init__.py`
- [ ] CHANGELOG.md updated
- [ ] README has install instructions (`pip install <name>` or `pipx install <name>`)

## PUBLISH

```bash
# Build
python -m build
# or
uv build

# Test the build locally
pip install dist/<name>-<version>-py3-none-any.whl

# Publish to TestPyPI first
python -m twine upload --repository testpypi dist/*

# Verify install from TestPyPI
pip install --index-url https://test.pypi.org/simple/ <name>

# Publish to PyPI
python -m twine upload dist/*
```

## POST-PUBLISH

- [ ] Verify install works from clean machine: `pipx install <name>`
- [ ] Tag the release in git: `git tag v<version> && git push --tags`
- [ ] Create GitHub release with changelog excerpt
- [ ] Update DEPLOYMENT.md (foundation file) with publish log

## ROLLBACK

If a published version is broken, do NOT delete it from PyPI (that breaks downstream installs). Instead, publish a patch version with the fix. PyPI does support yanking versions, which discourages new installs without breaking existing ones.
