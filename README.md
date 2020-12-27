# RadeonClockEnforcer

A lot of newer Radeon GPUs don't scale clocks well with some GPU-focused applications. You might be seeing only 300Mhz in a game after paying for a promised 1200Mhz+.

RadeonClockEnforcer is a single AutoHotkey script that forces maximum GPU & VRAM clock speeds while important applications are open. It automates OverdriveNTool's profile switching functionality for GPU and VRAM clocks & voltages. RCE uses application whitelists/blacklists and is fairly robust albeit very simple.

My beloved [ClockBlocker](https://www.guru3d.com/files-details/clockblocker-download.html) stopped working for me when I switched from Windows 7 to 10 and it seems like I'm not the only one, so I made a little program using AutoHotkey\_L to do the same sort of thing, but maybe even a little better since it doesn't artificially load the GPU at all in order to achieve max clocks.

## Instructions:

1. Download the release .zip and extract the main `\RadeonClockEnforcer` folder anywhere.
2. Follow the .lnk shortcut in `\RadeonClockEnforcer` to [download OverdriveNTool.exe](https://forums.guru3d.com/threads/overdriventool-tool-for-amd-gpus.416116/) and place it in that folder.
3. Read `\RadeonClockEnforcer\RCE\README_RadeonClockEnforcer.txt`, which will tell you to also read the OverdriveNTool docs.
4. After that, set up both of your OverdriveNTool profiles as suggested from `\RadeonClockEnforcer\RCE\OverDriveNTool_example.png`.
