#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
get_controls

# Source Device Info
source $controlfolder/device_info.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"

# Set variables
GAMEDIR="/$directory/ports/sonic1"
WIDTH=$((DISPLAY_WIDTH / 2))
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Set current virtual screen
if [ "$CFW_NAME" == "muOS" ]; then
  /opt/muos/extra/muxlog & CUR_TTY="/tmp/muxlog_info"
elif [ "$CFW_NAME" == "TrimUI" ]; then
  CUR_TTY="/dev/fd/1"
else
  CUR_TTY="/dev/tty0"
fi

cd $GAMEDIR

# Exports
LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$GAMEDIR/libs"

# Setup gl4es environment
if [ -f "${controlfolder}/libgl_${CFW_NAME}.txt" ]; then 
  source "${controlfolder}/libgl_${CFW_NAME}.txt"
else
  source "${controlfolder}/libgl_default.txt"
fi

# Permissions
$ESUDO chmod 666 /dev/tty0
$ESUDO chmod 666 /dev/tty1
$ESUDO chmod 777 $GAMEDIR/sonic2013
$ESUDO chmod 777 $GAMEDIR/sonicforever

# Modify ScreenWidth
if grep -q "^ScreenWidth=[0-9]\+" "$GAMEDIR/settings.ini"; then
    sed -i "s/^ScreenWidth=[0-9]\+/ScreenWidth=$WIDTH/" "$GAMEDIR/settings.ini"
else
    echo "Possible invalid or missing settings.ini!"
fi

# Check if running Sonic Forever
result=$(grep "^SonicForeverMod=true" "$GAMEDIR/mods/modconfig.ini")

if [ -n "$result" ]; then
    GAME=sonicforever
else
    GAME=sonic2013
fi

# Run the game
echo "Loading, please wait!" > $CUR_TTY
$GPTOKEYB $GAME -c "sonic.gptk" &
SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
./$GAME

$ESUDO kill -9 $(pidof gptokeyb)
$ESUDO systemctl restart oga_events &
printf "\033c" > /dev/tty1