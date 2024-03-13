<div align="center">
  <h1>xt-robnpcs</h1>
  <a href="https://dsc.gg/xtdev"> <img align="center" src="https://user-images.githubusercontent.com/101474430/233859688-2b3b9ecc-41c8-41a6-b2e3-a9f1aad473ee.gif"/></a><br>
</div>

# Features:
- QB / QBX / OX / ESX Support
- Rob local NPCs
- Secure checks preventing spam, robbing animals, robbing spawned peds from resources, etc
- Sets 'robbed' statebag on peds once they are robbed / run away / fight back, preventing them from being robbed again
- Required cop count, or zero
- Min / max payouts
- Blacklisted jobs
  - Set jobs can not rob locals
- Random Chances
  - Chance police are called when NPC is robbed
  - Chance ped has NO cash on them when robbed
  - Chance the ped decides to flee or beat your ass before or after robbing them, rather than surrendering
  - If ped fights back, random chance they have a weapon, random weapon is chosen from the config
  - Chance to receive items from peds pocket
- Animations
  - Ped puts hands up, then surrenders
  - Player does a 'robbing' animation
  - Ped does animation to get up and flee
- Easy configurations
  - Open function for adding money
  - Open function for adding items (use any inventory)
  - Open function for any dispatch

# [Preview](https://www.youtube.com/watch?v=s-Ihw-aHBbo)

# Dependencies:
- [ox_lib](https://github.com/overextended/ox_lib/releases)
- Supported Interaction Resources:
    - [qb-target](https://github.com/overextended/ox_target/releases) or [ox_target](https://github.com/overextended/ox_target/releases)
    - [interact](https://github.com/darktrovx/interact)