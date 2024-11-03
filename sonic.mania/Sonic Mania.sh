#!/bin/bash
# PORTMASTER: sonic.mania.zip, Sonic Mania.sh

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
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"

# Set variables
GAMEDIR="/$directory/ports/sonicmania"
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# CD and set permissions
cd $GAMEDIR
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1
$ESUDO chmod +x -R $GAMEDIR/*

# Exports
export LD_LIBRARY_PATH="usr/lib:$GAMEDIR/libs":$LD_LIBRARY_PATH
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

# Modify PixWidth
MED=320 # 4:3
HIGH=424 # 16:9

# Calculate the aspect ratio as a floating-point number
ASPECT=$(awk "BEGIN {print $DISPLAY_WIDTH / $DISPLAY_HEIGHT}")

# Set WIDTH based on aspect ratio comparisons
if awk "BEGIN {exit ($ASPECT > 1.3)}"; then
    WIDTH=$HIGH
elif awk "BEGIN {exit ($ASPECT <= 1.3)}"; then
    WIDTH=$MED
else
    WIDTH=$MED
fi

if grep -q "^pixWidth=[0-9]\+" "$GAMEDIR/Settings.ini"; then
    sed -i "s/^pixWidth=[0-9]\+/pixWidth=$WIDTH/" "$GAMEDIR/Settings.ini"
else
    echo "Possible invalid or missing Settings.ini!"
fi

# Run the game
$GPTOKEYB "sonicmania" & 
pm_platform_helper "sonicmania"
./sonicmania

# Cleanup
pm_finish