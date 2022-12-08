# FS22_UpgradableFactories
A Farming Simulator mod that increase production chains efficiency

## Features
- Production chains now have levels that you can increase.
- Upgrading a factory will cost you slightly more each level than buying a new building.
- Upgrading cost is vastly compensated by the gain in production speed.
- More production speed means more storage space.
- Because you don't have to build a new facility, you save on production costs.
- Factory value is increased when upgrading, so you can claim your investment back when selling a facility.

## Level System
A newly placed production will be at level 1 and will have the same price, speed and active costs than the default production. 
The maximum level a production can have is by default set to 10.

### Upgrade Price
Upgrading a facility will cost you and the upgrade price is dependent of the facility default buying price.
The upgrade price increase by 10% of the default buying price each level and is implemented as follow:
`buying_price + buying_price * 0.1 * level`.

### Total Value
Upgrading your facility will increase it's total value.
That meens when selling you can get, up to 50% of your investisment back (on base game and depending on how old the factory is).

### Speed
The gain in production speed is calculated by multiplying base cycles per month value by the level.
An additional bonus of 15% of the base cycles is applyed each level.
The formula to calculate production speed at a given level is `base_cycles * level + base_cycles * 0.15 * (level - 1)`.
`base_cycles` being the default cycles for a production (or one at level 1 when mod is install)

### Running cost
Following the same principle, the running cost of a production is increase when upgrading and you get a discount.
The running cost at a given level is calculated be the following formula `base_cost * level - base_cost * 0.1 * (lvl - 1)`.

### Storage
Storage capacity is function of the base capacity and the level too and is simply `base_capacity * level`

### Exemple
Here is a table to show what the above meens:

Level  | Upgrade Price | Total Value | Cycles / month | Costs / month  | Capacity
:----: | :----:        | :----:      | :----:         | :----:         | :----:  
1      | 10 000        | 10 000      | 120            | 10             | 25 000  
2      | 11 000        | 21 000      | 258 (+18)      | 19 (-1)        | 50 000  
3      | 12 000        | 33 000      | 396 (+36)      | 28 (-2)        | 75 000  
4      | 13 000        | 46 000      | 534 (+54)      | 37 (-3)        | 100 000 
5      | 14 000        | 60 000      | 672 (+72)      | 46 (-4)        | 125 000 

If we summurize, upgrading a factory to the level 5 will cost you 14k, for a total value of 60k. It will produce 672 goods per month (from which 72 are gain as a level 5 bonus), cost you 46 (instead of 50 for 5 base game productions) and have 125k storage capacity (so 5 the default one).

## Leveling System Limitations
With this system factories can reach insane production speeds which is too cheaty and unrealistic.
That's why we decided to implement a maximum level feature, by default productions can't go beyound the level 10.
But in some cases you might want to go past this limitation.

`ufMaxLevel <new_max_level>` console command allow you to do that, `<new_max_level>` being the new maximum level the productions will now reach.
But be carefull, if you have factories level 15 and you set new_max_level to 10, they will be downgraded to level 10 and no money will be refound.
For performance reason you wont be able to set `<new_max_level>` under 1 over over 99.
Note that the max level is saved in `upgradableFactories.xml` file locate in your savegame folder, editing this file is an other way to set the maximum reachable level.