# The Modest Toolset

The Docker image copies mcsta from the Modest Toolset v3.1.315-g0a0763b35 unpacked
in this directory, one per architecture as Docker names them:

- `amd64/Modest/`, from `Modest-Toolset-v3.1.315-g0a0763b35-linux-x64.zip`
- `arm64/Modest/`, from `Modest-Toolset-v3.1.315-g0a0763b35-linux-arm64.zip`

The website https://www.modestchecker.net/downloads/ only offers the latest version,
so it is kept here to build the image with the same mcsta later on. `License.txt` is
the license of the Modest Toolset for this artifact, which permits its redistribution
as part of it. The zips are the releases with only `Modest/License.txt` replaced by
`License.txt`; `SHA256SUMS` holds their checksums with that license.
