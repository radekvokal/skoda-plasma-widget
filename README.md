# Škoda Vehicle Monitor — KDE Plasma 6 Widget

A KDE Plasma 6 desktop widget that displays real-time information about your Škoda connected vehicle using the [MyŠkoda Public API](https://public.api.connect.skoda-auto.cz/docs/swagger-ui/index.html).

![Škoda Vehicle Monitor widget](https://raw.githubusercontent.com/radekvokal/skoda-plasma-widget/main/screenshot.png)

## Features

- Vehicle name, license plate, and engine type
- Mileage (odometer)
- Fuel level with color-coded progress bar and remaining range
- AdBlue range
- Security status — doors, windows, trunk, bonnet, lights, lock state
- Live parking location on an interactive OpenStreetMap
- Compact panel representation showing fuel % and range
- Automatic data refresh (configurable interval, default 15 minutes)
- Response caching — survives API rate limits and shows last known data
- Configurable background opacity

## Requirements

- KDE Plasma 6
- Qt 6 with QtLocation and QtPositioning modules
- A Škoda connected vehicle with the MyŠkoda app
- An API key from the MyŠkoda app ([how to create one](https://public.api.connect.skoda-auto.cz/docs/swagger-ui/index.html))

### Installing Qt6 dependencies

**Fedora:**
```bash
sudo dnf install qt6-qtlocation qt6-qtpositioning
```

**Arch Linux:**
```bash
sudo pacman -S qt6-location qt6-positioning
```

**Ubuntu/Debian:**
```bash
sudo apt install qml6-module-qtlocation qml6-module-qtpositioning
```

## Installation

### From the KDE Store

1. Right-click your desktop or panel and select **Add Widgets**
2. Click **Get New Widgets** > **Download New Plasma Widgets**
3. Search for **Škoda Vehicle Monitor** and click **Install**

Alternatively, download the `.plasmoid` package directly from [the OpenDesktop store page](https://www.opendesktop.org/p/2380548/) and install it with:

```bash
kpackagetool6 --type Plasma/Applet --install skoda-vehicle-monitor.plasmoid
```

### From source

Clone the repository and copy the widget to your local Plasma widgets directory:

```bash
git clone https://github.com/radekvokal/skoda-plasma-widget.git
mkdir -p ~/.local/share/plasma/plasmoids/org.skoda.vehicle-monitor
cp -r skoda-plasma-widget/contents skoda-plasma-widget/metadata.json \
    ~/.local/share/plasma/plasmoids/org.skoda.vehicle-monitor/
```

Then restart Plasma or log out and back in:

```bash
plasmashell --replace &
```

### Using kpackagetool6

```bash
git clone https://github.com/radekvokal/skoda-plasma-widget.git
kpackagetool6 --type Plasma/Applet --install skoda-plasma-widget
```

To update an existing installation:

```bash
kpackagetool6 --type Plasma/Applet --upgrade skoda-plasma-widget
```

## Configuration

1. Add the widget to your desktop or panel (right-click > Add Widgets > search "Škoda Vehicle Monitor")
2. Right-click the widget > Configure
3. Enter your **VIN** (Vehicle Identification Number) and **API Key**
4. Optionally adjust the update interval and background opacity

### Getting your API key

API keys are created and managed in the MyŠkoda mobile app. Keys are bound to the vehicles you select when creating them. For details, see the [MyŠkoda Public API documentation](https://public.api.connect.skoda-auto.cz/docs/swagger-ui/index.html).

## API Reference

This widget uses the [MyŠkoda Public API](https://public.api.connect.skoda-auto.cz/docs/swagger-ui/index.html) (v1.1.0). The API is rate-limited — the widget caches the last successful response so your vehicle data remains visible during rate limit periods.

## License

GPL-3.0+
