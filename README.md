# statuspage
A status page for [optimistic.cloud](https://optimistic.cloud)

## Features

- Periodically pings services listed in [urls.json](./urls.json) and logs their status in the [logs/](logs/) directory
- Generates a static HTML status page from log data, viewable at [status.optimistic.cloud](https://status.optimistic.cloud)
- Sends a ping to [healthchecks.io](https://healthchecks.io) for each service