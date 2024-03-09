function Get-Trinket
    {
    <#
    .Synopsis
    Gets a item from the trinket table
    .Description
    Gets a item from the trinket table, either by rolling a D100 or by looking up the number you specify
    .Parameter DiceRoll
    Your manual D100 dice roll
    .Example
    Get-Trinket
    Grab a random trinket from the offical trinket table in the Players Handbook and returns it
    .EXAMPLE
    Get-Trinket -DiceRoll 42
    Returns the trinket that corresponds to the number 42 in the trinket table from the Players Handbook
    .Link
    https://github.com/PetterTech/DemoStuff
    #>
        [CmdletBinding()] 
            Param (
                [Parameter(Mandatory=$False,Position=0,HelpMessage='Your manual D100 dice roll')][ValidateRange(1, 100)][int]$DiceRoll
            )

    Begin {
        
        #Do a dice roll if none specified
        Write-Verbose "Rolling a d100 if none specified"
        if (!($DiceRoll)) {
            Write-Verbose "No dice roll specified, rolling a d100"
            try {
                $d100 = Get-Random -Minimum 1 -Maximum 100 -ErrorAction Stop
                write-verbose "Rolled a d100, got $($d100)"
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to roll a d100"
                Exit
            }
        }

        else {
            Write-Verbose "Using the specified dice roll"
            $d100 = $DiceRoll
        }
        
        # Define the trinket table
        Write-Verbose "Defining the trinket table"
        try {
            $TrinketTable = @()
            $TrinketTable += "A mummified goblin hand"
            $TrinketTable += "A piece of crystal that faintly glows in the moonlight"
            $TrinketTable += "A gold coin minted in an unknown land"
            $TrinketTable += "A diary written in a language you don't know"
            $TrinketTable += "A brass ring that never tarnishes"
            $TrinketTable += "An old chess piece made from glass"
            $TrinketTable += "A pair of knucklebone dice, each with a skull symbol on the side that would normally show six pips"
            $TrinketTable += "A small idol depicting a nightmarish creature that gives you unsettling dreams when you sleep near it"
            $TrinketTable += "A rope necklace from which dangles four mummified elf fingers"
            $TrinketTable += "The deed for a parcel of land in a realm unknown to you"
            $TrinketTable += "A 1-ounce block made from an unknown material"
            $TrinketTable += "A small cloth doll skewered with needles"
            $TrinketTable += "A tooth from an unknown beast"
            $TrinketTable += "An enormous scale, perhaps from a dragon"
            $TrinketTable += "A bright green feather"
            $TrinketTable += "An old divination card bearing your likeness"
            $TrinketTable += "A glass orb filled with moving smoke"
            $TrinketTable += "A 1-pound egg with a bright red shell"
            $TrinketTable += "A pipe that blows bubbles"
            $TrinketTable += "A glass jar containing a weird bit of flesh floating in pickling fluid"
            $TrinketTable += "A tiny gnome-crafted music box that plays a song you dimly remember from your childhood"
            $TrinketTable += "A small wooden statuette of a smug halfling"
            $TrinketTable += "A brass orb etched with strange runes"
            $TrinketTable += "A multicolored stone disk"
            $TrinketTable += "A tiny silver icon of a raven"
            $TrinketTable += "A bag containing forty-seven humanoid teeth, one of which is rotten"
            $TrinketTable += "A shard of obsidian that always feels warm to the touch"
            $TrinketTable += "A dragon's bony talon hanging from a plain leather necklace"
            $TrinketTable += "A pair of old socks"
            $TrinketTable += "A blank book whose pages refuse to hold ink, chalk, graphite, or any other substance or marking"
            $TrinketTable += "A silver badge in the shape of a five-pointed star"
            $TrinketTable += "A knife that belonged to a relative"
            $TrinketTable += "A glass vial filled with nail clippings"
            $TrinketTable += "A rectangular metal device with two tiny metal cups on one end that throws sparks when wet"
            $TrinketTable += "A white, sequined glove sized for a human"
            $TrinketTable += "A vest with one hundred tiny pockets"
            $TrinketTable += "A small, weightless stone block"
            $TrinketTable += "A tiny sketch portrait of a goblin"
            $TrinketTable += "An empty glass vial that smells of perfume when opened"
            $TrinketTable += "A gemstone that looks like a lump of coal when examined by anyone but you"
            $TrinketTable += "A scrap of cloth from an old banner"
            $TrinketTable += "A rank insignia from a lost legionnaire"
            $TrinketTable += "A tiny silver bell without a clapper"
            $TrinketTable += "A mechanical canary inside a gnomish lamp"
            $TrinketTable += "A tiny chest carved to look like it has numerous feet on the bottom"
            $TrinketTable += "A dead sprite inside a clear glass bottle"
            $TrinketTable += "A metal can that has no opening but sounds as if it is filled with liquid, sand, spiders, or broken glass (DMs choice)"
            $TrinketTable += "A glass orb filled with water, in which swims a clockwork goldfish"
            $TrinketTable += "A silver spoon with an M engraved on the handle"
            $TrinketTable += "A whistle made from gold-colored wood"
            $TrinketTable += "A dead scarab beetle the size of your hand"
            $TrinketTable += "Two toy soldiers, one with a missing head"
            $TrinketTable += "A small box filled with different-sized buttons"
            $TrinketTable += "A candle that can't be lit"
            $TrinketTable += "A tiny cage with no door"
            $TrinketTable += "An old key"
            $TrinketTable += "An indecipherable treasure map"
            $TrinketTable += "A hilt from a broken sword"
            $TrinketTable += "A rabbit's foot"
            $TrinketTable += "A glass eye"
            $TrinketTable += "A cameo carved in the likeness of a hideous person"
            $TrinketTable += "A silver skull the size of a coin"
            $TrinketTable += "An alabaster mask"
            $TrinketTable += "A pyramid of sticky black incense that smells very bad"
            $TrinketTable += "A nightcap that, when worn, gives you pleasant dreams"
            $TrinketTable += "A single caltrop made from bone"
            $TrinketTable += "A gold monocle frame without the lens"
            $TrinketTable += "A 1-inch cube, each side painted a different color"
            $TrinketTable += "A crystal knob from a door"
            $TrinketTable += "A small packet filled with pink dust"
            $TrinketTable += "A fragment of a beautiful song, written as musical notes on two pieces of parchment"
            $TrinketTable += "A silver teardrop earring made from a real teardrop"
            $TrinketTable += "The shell of an egg painted with scenes of human misery in disturbing detail"
            $TrinketTable += "A fan that, when unfolded, shows a sleeping cat"
            $TrinketTable += "A set of bone pipes"
            $TrinketTable += "A four-leaf clover pressed inside a book discussing manners and etiquette"
            $TrinketTable += "A sheet of parchment upon which is drawn a complex mechanical contraption"
            $TrinketTable += "An ornate scabbard that fits no blade you have found so far"
            $TrinketTable += "An invitation to a party where a murder has happened"
            $TrinketTable += "A bronze pentacle with an etching of a rat's head in its center"
            $TrinketTable += "A purple handkerchief embroidered with the name of a powerful archmage"
            $TrinketTable += "Half a floot plan for a temple, a castle or another structure"
            $TrinketTable += "A bit of folded cloth that, when unfolded, turns into a stylish cap"
            $TrinketTable += "A receipt of deposit at a bank in a far-flung city"
            $TrinketTable += "A diary with seven missing pages"
            $TrinketTable += "An empty silver snuffbox bearing an inscription on the surface that says 'dreams'"
            $TrinketTable += "An iron holy symbol devoted to an unknown god"
            $TrinketTable += "A book that tells the story of a legendary hero's rise and fall, with the last chapter missing"
            $TrinketTable += "A vial of dragon blood"
            $TrinketTable += "An ancient arrow of elven design"
            $TrinketTable += "A needle that never bends"
            $TrinketTable += "An ornate brooch of dwarven design"
            $TrinketTable += "An empty wine bottle bearing a pretty label that says, 'The Wizard of Wines Winery, Red Dragon Crush, 331422-W'"
            $TrinketTable += "A mosaic tile with a multicolored, glazed surface"
            $TrinketTable += "A petrified mouse"
            $TrinketTable += "A black pirate flag adorned with a dragon's skull and crossbones"
            $TrinketTable += "A tiny mechanical crab or spider that moves about when it's not being observed"
            $TrinketTable += "A glass jar containing lard with a label that reads, 'Griffon Grease'"
            $TrinketTable += "A wooden box with a ceramic bottom that holds a living worm with a head on each end of its body"
            $TrinketTable += "A metal urn containing the ashes of a hero"
        }
        catch {
            Write-Verbose $Error[0]
            Write-Error "Failed to define the trinket table"
            Exit
        }
	
    }

    Process {

        # Figure out which trinket to return
        Write-Verbose "Figuring out which trinket to return"
        try {
            Write-Verbose "Will return number $($d100-1) in the table, corresponding to $(d100) in the players handbook"
            $TrinketToReturn = $TrinketTable[$d100-1]
            Write-Verbose "Returning $($TrinketToReturn)"
        }
        catch {
            Write-Verbose $Error[0]
            Write-Error "Failed to figure out which trinket to return"
            Exit
        }

        # Return the trinket
        Write-Verbose "Returning the trinket"
        try {
            Write-Output $TrinketToReturn
        }
        catch {
            Write-Verbose $Error[0]
            Write-Error "Failed to return the trinket"
            Exit
        }
       
    }

    End {

        # Clear the variables
        Write-Verbose "Clearing the variables"
        try {
            Clear-Variable -Name d100 -ErrorAction SilentlyContinue
            Clear-Variable -Name TrinketTable -ErrorAction SilentlyContinue
            Clear-Variable -Name TrinketToReturn -ErrorAction SilentlyContinue

        }
        catch {
            
        }
    }
}