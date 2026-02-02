# HMC Reborn (World of Warcraft Addon)

A lightweight addon that plays custom sounds via slash commands or a GUI soundboard.

## Features
- **Slash Commands**: Play sounds quickly while typing (e.g., `/hmc soundname`).
- **Soundboard UI**: Browse and play all available sounds from a scrollable window (`/hmc ui`).
- **Huge Library**: Includes over 380 custom sounds.

## Installation

1.  **Locate the Folder**: The addon is located in `c:\Personal\Projects\hmc_reborn`.
2.  **Copy to WoW**: Copy the entire `hmc_reborn` folder.
3.  **Paste**: Paste it into your World of Warcraft AddOns directory:
    - **Retail**: `World of Warcraft\_retail_\Interface\AddOns\`
    - **Classic**: `World of Warcraft\_classic_\Interface\AddOns\`
4.  **Restart WoW**: Fully close and restart the game client.

## Usage

### Slash Commands
Play a sound by name:
```
/hmc <sound_name>
```
Example: `/hmc agyonvertel`

### Soundboard
Open the graphical interface:
```
/hmc
```
or
```
/hmc ui
```
Click any button to play the corresponding sound.

## Troubleshooting
- **"Addon is incompatible"**: Ensure the `hmc_reborn.toc` file has the correct `## Interface` number for your WoW version (currently set to **120000** for WoW Midnight).
- **Sound not playing**: Make sure your "Sound Effects" volume is enabled in WoW settings.

## Adding New Sounds
This addon uses a database in `sounds.lua`. To add new sounds:
1.  Add the `.mp3` file to the `Sounds` directory.
2.  Edit `sounds.lua` and add a new entry to the `HMC_Sounds` table:
    ```lua
    ["newsoundname"] = "Interface\\AddOns\\hmc_reborn\\Sounds\\category\\filename.mp3",
    ```
3.  Restart WoW.
