# Changelog

All notable changes to this project will be documented in this file. See [commit-and-tag-version](https://github.com/absolute-version/commit-and-tag-version) for commit guidelines.

## 1.0.0 (2026-11-14)

### Features

* deploy RomM against an existing database, with claims for its resources, assets and task queue, a library volume and config.yml from values ([f094548](https://github.com/tonylea/helm-chart-romm/commit/f09454814fbbfb0bf524a362ba80883364f88bd7))

### Bug Fixes

* hash only config into the pod's checksum, so a chart release alone doesn't restart RomM ([fe24abf](https://github.com/tonylea/helm-chart-romm/commit/fe24abfe14494f4a58016ee8abd538e39cc16feb))

### Documentation

* describe the chart, its values and how to contribute ([62bbebb](https://github.com/tonylea/helm-chart-romm/commit/62bbebb4bdb0d03f7acfb24b3b3cca12ab9aa4b0))
