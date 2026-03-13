# Development Workflow

Typical workflow:

1. Enter development environment

```bash
nix develop
```

2. Modify modules or apps

3. Build system image

```bash
just airsensor::build
```

4. Flash to SD card and boot

```bash
just airsensor::flash /dev/sdX
```

5. Deploy updates over the air

```bash
just airsensor::deploy
```
