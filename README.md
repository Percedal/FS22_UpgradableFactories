# FS22_UpgradableFactories
A Farming Simulator mod that increase production chains efficiency

## Features
- Production chains have levels that you can increase.
- Upgrading a factory will cost you slightly more each level than buying a new building.
- Upgrading cost is vastly compensated by the gain in production speed.
- More production speed meens more storage space.
- Because you don't have to build a new facility, you save on productions cost.
- The selling price of your productions have been updated. Seeling will bring you back 75% of the overall money you invested in it.

## Level System
A newly placed production will be at level 1 and will have the same price, speed and active costs than the default production. There is not maximum level a production can have.

Upgrading a facility will cost you and the upgrade price is dependent of the facility default buying price.
The upgrade price increase by 10% of the default buying price each level and is implemented as follow:
`buying_price + buying_price * 0.1 * level`.

Upgrading your facility will increase it's total value.
That meens when selling you can get, depending how old is the production, up to 50% of your investisment back.

The gain in production speed is calculated by multiplying base cycles per month value by the level.
An additional bonus of 15% of the base cycles is applyed each level.
The formula to calculate production speed at a given level is `base_cycles * level + base_cycles * 0.15 * (level - 1)`.
`base_cycles` being the default cycles for a production (or one at level 1 when mod is install)

Following the same principle, the running cost of a production is increase when upgrading and you get a discount.
The running cost at a given level is calculated be the following formula `base_cost * level - base_cost * 0.1 * (lvl - 1)`.

Storage capacity is function of the base capacity and the level too and is simply `base_capacity * level`

### Exemple
Level  | Upgrade Price | Cycles / month | Costs  | Capacity | Total Value
:----: | :----:        | :----:         | :----: | :----:   | :----:
1      | 10 000        | 120            | 10     | 25 000   | 10 000
2      | 11 000        | 258 (+18)      | 19     | 50 000   | 21 000
3      | 12 000        | 396 (+36)      | 28     | 75 000   | 33 000
4      | 13 000        | 534 (+54)      | 37     | 100 000  | 46 000
5      | 14 000        | 672 (+72)      | 46     | 125 000  | 60 000