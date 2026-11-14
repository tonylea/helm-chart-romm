# helm-chart-romm

Deploys [RomM](https://romm.app/) from its official image, [`rommapp/romm`](https://github.com/rommapp/romm).
RomM scans a library of retro game ROMs, fetches their metadata and artwork, and serves them to browse, download and play in the browser.

The chart runs one replica:

- A Deployment that stops the old pod before starting the new one.
  RomM's task queue is a Valkey inside the pod, and its claims are `ReadWriteOnce`.
- A PersistentVolumeClaim each for `/romm/resources` (fetched covers, screenshots and manuals), `/romm/assets` (uploaded saves and states) and `/redis-data` (the task queue).
  They're ordinary claims the chart owns, so their sizes can be raised in the values; most storage classes allow claims to grow but not shrink.
- The library volume at `/romm/library`, an empty directory unless another volume is given.
- `config.yml` from the values, in a ConfigMap mounted read-only at `/romm/config`.
  The pod restarts when it changes.
- A Service on RomM's port, 8080, and an optional Gateway API `HTTPRoute` to it.
- A start-up, liveness and readiness probe on RomM's `/api/heartbeat`.
  Start-up gets 5 minutes, since the image waits for Valkey and runs the database migrations before RomM listens.

RomM needs a database server, which the chart doesn't deploy.
RomM exposes no Prometheus metrics, so the chart has no `ServiceMonitor` or dashboards.

## Values

| Value | Default |
| --- | --- |
| `image.repository` | `rommapp/romm` |
| `image.tag` | the chart's `appVersion` |
| `timezone` | `Etc/UTC` |
| `authSecretKey.existingSecret` | none; required |
| `authSecretKey.key` | `key` |
| `database.driver` | `mariadb` |
| `database.host` | none; required |
| `database.port` | `3306` |
| `database.name` | `romm` |
| `database.user` | `romm` |
| `database.password.existingSecret` | none; required |
| `database.password.key` | `password` |
| `envFromSecret` | none |
| `env` | none |
| `config` | none |
| `resources` | requests `cpu: 250m`, `memory: 512Mi`; no limits |
| `persistence.resources.claimName` | `<release>-resources` |
| `persistence.resources.size` | `10Gi` |
| `persistence.resources.storageClassName` | the cluster's default class |
| `persistence.assets.claimName` | `<release>-assets` |
| `persistence.assets.size` | `10Gi` |
| `persistence.assets.storageClassName` | the cluster's default class |
| `persistence.redisData.claimName` | `<release>-redis-data` |
| `persistence.redisData.size` | `1Gi` |
| `persistence.redisData.storageClassName` | the cluster's default class |
| `library.readOnly` | `false` |
| `library.volume` | an `emptyDir` |
| `affinity` | none |
| `httpRoute.enabled` | `false` |
| `httpRoute.parentRefs` | none; required when enabled |
| `httpRoute.hostnames` | none |

`authSecretKey` names a Secret holding the key RomM signs sessions and tokens with, passed as `ROMM_AUTH_SECRET_KEY`; `openssl rand -hex 32` makes one.
Without it the image would make a new key on every start, logging everyone out, so the chart requires it.

`database` is passed as `ROMM_DB_DRIVER`, `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER` and `DB_PASSWD`.
`driver` is `mariadb`, `mysql` or `postgresql`; set `port` to match.
The database and user have to exist; RomM creates its tables on start-up.

`envFromSecret` names a Secret whose keys are RomM variable names, all passed to RomM: the place for metadata providers' keys, such as `IGDB_CLIENT_ID`, `IGDB_CLIENT_SECRET` or `SCREENSCRAPER_PASSWORD`.
`env` sets any other [RomM variable](https://docs.romm.app/latest/reference/environment-variables/) by name, for example `ENABLE_SCHEDULED_RESCAN: true`.

`config` is written as RomM's [`config.yml`](https://docs.romm.app/latest/reference/configuration-file/): exclusions, platform bindings and versions, folder structure, scan priorities and EmulatorJS settings.
It's mounted read-only, so changes made in RomM's Library Management don't persist past a restart; change the values instead.

`library.volume` is any Kubernetes volume source, holding RomM's [folder structure](https://docs.romm.app/latest/getting-started/folder-structure/), for example `roms/{platform}` and `bios/{platform}`.
RomM writes to it when ROMs are uploaded or deleted, so it's read-write unless `library.readOnly` is `true`.

## Requirements

- A MariaDB, MySQL or PostgreSQL server, with a database and a user for RomM.
- The auth key's and the database password's Secrets.
- A storage class for the claims, the cluster's default unless named.
- The Gateway API's `HTTPRoute` CRD, when `httpRoute.enabled` is set.

## Usage

```sh
helm repo add romm https://tonylea.github.io/helm-chart-romm
helm install romm romm/romm --values my-values.yaml
```

```yaml
timezone: Europe/London
authSecretKey:
  existingSecret: romm-auth
database:
  host: mariadb.databases
  password:
    existingSecret: romm-database
envFromSecret: romm-metadata
library:
  volume:
    hostPath:
      path: /srv/games
      type: Directory
config:
  exclude:
    platforms:
      - ps2
```

## Development

Pull requests run:

- `helm lint --strict`, and the rendered chart checked by kubeconform against Kubernetes 1.37, with `ci/kind-values.yaml`.
- helm-unittest's tests in `tests/`.
- An install and upgrade with chart-testing in a kind cluster, against a throwaway MariaDB from `ci/kind`.

Commits follow Conventional Commits.
Releases are versioned and tagged automatically from `main`, and published to the Helm repository on this repo's GitHub Pages.
