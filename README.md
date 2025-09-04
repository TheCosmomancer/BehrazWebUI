# 💫 Local AI Chat Panel for Hyprland (Ollama + Open WebUI)

These scripts integrate **[Ollama](https://ollama.ai/)** with **[Open WebUI](https://github.com/open-webui/open-webui)** inside **Hyprland** to provide a fast, local, and privacy-friendly AI chat panel.  

including:
- 🐳 A **Docker setup** for running Open WebUI with Ollama.  
- 🎛️ A **controller script (`ai_control.sh`)** to start/stop Ollama and the WebUI container.  
- 🪟 A **Hyprland panel script (`ai_panel.sh`)** that toggles a sleek left-side dropdown AI panel with animations.  

---

## ✨ Features

- **Local AI only**: Models run with Ollama on your machine.  
- **One-command start/stop**: Manage services via `ai_control.sh`.  
- **Hyprland integration**: Toggle the AI panel from anywhere with `ai_panel.sh`.  
- **Customizable**: Easily adjust panel width, opacity, and animation.  
- **Persistent storage**: Model and WebUI data are stored in mounted volumes.  

---

## 📦 Requirements

- Linux with **Hyprland** (Wayland compositor)  
- **Docker** (for Open WebUI)  
- **Ollama** installed locally (`ollama serve` must be available)  
- **Chromium** (panel opens in app mode)  
- **jq** + **hyprctl** (for window handling)  

---

## 🚀 Setup

### 1. Run Open WebUI (Docker)

Here’s a general `docker run` command (adjust paths to your setup):

```bash
docker run -d --network host \
  -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
  -v /usr/local/bin/ollama:/usr/local/bin/ollama:ro \
  -v /path/to/ollama-models:/root/.ollama \
  -v open-webui:/app/backend/data \
  --env OLLAMA_MODELS=/root/.ollama \
  --name open-webui-cpu --restart always \
  ghcr.io/open-webui/open-webui:main
```

📌 Replace `/path/to/ollama-models` with the actual directory where your Ollama models are stored.

---

### 2. Use the Control Script

`ai_control.sh` helps manage both Ollama and the WebUI container.

```bash
# Start Ollama + Open WebUI
./ai_control.sh start

# Stop everything
./ai_control.sh stop
```

Logs are stored in `/tmp/ollama_serve.log`.

---

### 3. Hyprland Dropdown Panel

`ai_panel.sh` creates a **left-side slide-in panel** with Chromium running Open WebUI.

```bash
# Toggle the AI panel
./ai_panel.sh
```

- The panel slides in/out with smooth animation.  
- Adjust **width, height, opacity, and animation steps** inside the script.  
- Debug mode available:
  ```bash
  ./ai_panel.sh -d
  ```

---

## ⚙️ Configuration

Inside `ai_panel.sh` you can tweak:

- `WIDTH_PERCENT` – panel width (default `40%`)  
- `HEIGHT_PERCENT` – panel height (default `96%`)  
- `SLIDE_STEPS` – animation smoothness (default `5`)  
- `CHROMIUM_CMD` – change browser command (e.g., Brave instead of Chromium)  

---

## 🎮 Usage Example (Workflow)

1. Start backend services:
   ```bash
   ./ai_control.sh start
   ```
2. Toggle the Hyprland AI panel:
   ```bash
   ./ai_panel.sh
   ```
3. Ask your local AI questions — all data stays on your machine.  
4. Hide panel with `./ai_panel.sh` again.  
5. Stop services when done:
   ```bash
   ./ai_control.sh stop
   ```

---

## ⌨️ Hyprland Keybinding

To make toggling the AI panel seamless, you can bind it to a hotkey in your **`hyprland.conf`**.  

For example, to use **Alt + A**:  

```ini
# Open/close the AI panel with Alt + A
bind = ALT, A, exec, ~/path/to/ai_panel.sh
```

📌 Replace `~/path/to/` with the actual path to your script.  

Now pressing **Alt + A** will smoothly slide the AI panel in/out!  

---

## 🎥 Demo

Here’s what the AI panel looks like in action:  

![AI Panel Demo](demo/demo.GIF)  

- The panel slides in from the **left** with smooth animation.  
- Runs inside **Chromium app mode** for a clean, distraction-free UI.  
- Easily toggled with **Alt + A**.  


---

## 📂 Repository Structure

```
.
├── ai_control.sh   # Start/stop Ollama + WebUI
├── ai_panel.sh     # Hyprland dropdown panel script
├── demo/           # Demo media (gif/mp4)
└── README.md       # This file
```
