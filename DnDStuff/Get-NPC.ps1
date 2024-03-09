function Get-NPC
    {
    <#
    .Synopsis
    Generates an NPC
    .Description
    This function generates either a completely random NPC or an NPC based your input
    .Parameter Race
    The race of the NPC
    .Parameter Appearance
    The appearance of the NPC
    .Parameter HighAbility
    The high ability of the NPC
    .Parameter LowAbility
    The low ability of the NPC
    .Parameter Talent
    The talent of the NPC
    .Parameter Mannerism
    The mannerism of the NPC
    .Example
    Get-NPC
    Generates a random NPC
    .Example
    Get-NPC -Race Human
    Generates a human, random NPC
    .Link
    https://github.com/PetterTech/DemoStuff
    #>
        [CmdletBinding()] 
            Param (
                [Parameter(Mandatory=$False,Position=0,HelpMessage='The race of the NPC')][ValidateSet(
                    'Human',
                    'Elf',
                    'Dwarf',
                    'Halfling',
                    'Gnome',
                    'Half-Elf',
                    'Half-Orc',
                    'Tiefling',
                    'Dragonborn'
                    )][string]$Race,
                [Parameter(Mandatory=$False,Position=1,HelpMessage='The appearance of the NPC')][ValidateSet(
                    'Distinctive jewelry',
                    'Piercings',
                    'Flamboyant or outlandish clothes',
                    'Formal, clean clothes',
                    'Ragged, dirty clothes',
                    'Pronounced scar',
                    'Missing teeth',
                    'Missing fingers',
                    'Unusual eye color',
                    'Tattoos',
                    'Birthmark',
                    'Unusual skin color',
                    'Bald',
                    'Braided beard or hair',
                    'Unusual hair color',
                    'Nervous eye twitch',
                    'Distinctive nose',
                    'Distinctive posture (crooked or rigid)',
                    'Exceptionally beautiful',
                    'Exceptionally ugly'
                    )][string]$Appearance,
                [Parameter(Mandatory=$False,Position=2,HelpMessage='The high ability of the NPC')][ValidateSet(
                    'Strength',
                    'Dexterity',
                    'Constitution',
                    'Intelligence',
                    'Wisdom',
                    'Charisma'
                    )][string]$HighAbility,
                [Parameter(Mandatory=$False,Position=3,HelpMessage='The low ability of the NPC')][ValidateSet(
                    'Strength',
                    'Dexterity',
                    'Constitution',
                    'Intelligence',
                    'Wisdom',
                    'Charisma'
                    )][string]$LowAbility,
                [Parameter(Mandatory=$False,Position=4,HelpMessage='The talent of the NPC')][ValidateSet(
                    'Plays a musical instrument',
                    'Speaks several languages fluently',
                    'Unbelievably lucky',
                    'Perfect memory',
                    'Great with animals',
                    'Great with children',
                    'Great at solving puzzles',
                    'Great at one game',
                    'Great at impersonations',
                    'Draws beautifully',
                    'Paints beautifully',
                    'Sings beautifully',
                    'Drinks everyone under the table',
                    'Expert carpenter',
                    'Expert cook',
                    'Expert dart thrower and rock skipper',
                    'Expert juggler',
                    'Skilled actor and master of disguise',
                    'Skilled dancer',
                    'Knows thieves cant'
                    )][string]$Talent,
                [Parameter(Mandatory=$False,Position=5,HelpMessage='The mannerism of the NPC')][ValidateSet(
                    'Prone to singing, whistling, or humming quietly',
                    'Speaks in rhyme or some other peculiar way',
                    'Particularly low or high voice',
                    'Slurs words, lisps, or stutters',
                    'Enunciates overly clearly',
                    'Speaks loudly',
                    'Whispers',
                    'Uses flowery speech or long words',
                    'Frequently uses the wrong word',
                    'Uses colorful oaths and exclamations',
                    'Makes constant jokes or puns',
                    'Prone to predictions of doom',
                    'Fidgets',
                    'Squints',
                    'Stares into the distance',
                    'Chews something',
                    'Paces',
                    'Taps fingers',
                    'Bites fingernails',
                    'Twirls hair or tugs beard'
                    )][string]$Mannerism,
                [Parameter(Mandatory=$False,Position=6,HelpMessage='The interaction trait of the NPC')][ValidateSet(
                    'Argumentative',
                    'Arrogant',
                    'Blustering',
                    'Rude',
                    'Curious',
                    'Friendly',
                    'Honest',
                    'Hot tempered',
                    'Irritable',
                    'Ponderous',
                    'Quiet',
                    'Suspicious'
                    )][string]$Interaction,
                [Parameter(Mandatory=$False,Position=7,HelpMessage='The alignment of the NPC')][ValidateSet(
                    'Lawful Good',
                    'Neutral Good',
                    'Chaotic Good',
                    'Lawful Neutral',
                    'True Neutral',
                    'Chaotic Neutral',
                    'Lawful Evil',
                    'Neutral Evil',
                    'Chaotic Evil'
                    )][string]$Alignment,
                [Parameter(Mandatory=$False,Position=8,HelpMessage='The ideal of the NPC')][ValidateSet(
                    'Beauty',
                    'Charity',
                    'Greater Good',
                    'Life',
                    'Respect',
                    'Self-Sacrifice',
                    'Domination',
                    'Greed',
                    'Might',
                    'Pain',
                    'Retribution',
                    'Slaughter',
                    'Change',
                    'Creativity',
                    'Freedom',
                    'Honesty',
                    'Independence',
                    'Knowledge',
                    'Live and Let Live',
                    'Moderation',
                    'Nation',
                    'People',
                    'Redemption',
                    'Self-Knowledge'
                    )][string]$Ideal,
                [Parameter(Mandatory=$False,Position=9,HelpMessage='The bond of the NPC')][ValidateSet(
                    'Dedicated to fulfilling a personal life goal',
                    'Protective of close family members',
                    'Protective of colleagues or compatriots',
                    'Loyal to a benefactor, patron, or employer',
                    'Captivated by a romantic interest',
                    'Drawn to a special place',
                    'Protective of a sentimental keepsake',
                    'Protective of a valuable possession',
                    'Out for revenge'
                    )][string]$Bond,
                [Parameter(Mandatory=$False,Position=10,HelpMessage='The flaw or secret of the NPC')][ValidateSet(
                    'Forbidden love or susceptibility to romance',
                    'Enjoys decadent pleasures',
                    'Arrogance',
                    'Envies another creatures possessions or station',
                    'Overpowering greed',
                    'Prone to rage',
                    'Has a powerful enemy',
                    'Prone to sudden suspicion',
                    'Shameful or scandalous history',
                    'Secret crime or misdeed',
                    'Possession of forbidden lore',
                    'Foolhardy bravery'
                    )][string]$FlawsAndSecrets
                  )
    Begin {

        # Generating tables
        
        ## Generating the race table
        if (!($Race)) {
            try {
                $RaceTable = @('Human','Elf','Dwarf','Halfling','Gnome','Half-Elf','Half-Orc','Tiefling','Dragonborn')        
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to generate race table"
                exit
            }
        }
        
        ## Generating the appearance table
        if (!($Appearance)) {
            try {
                $AppearanceTable = @('Distinctive jewelry','Piercings','Flamboyant or outlandish clothes','Formal, clean clothes','Ragged, dirty clothes','Pronounced scar','Missing teeth','Missing fingers','Unusual eye color','Tattoos','Birthmark','Unusual skin color','Bald','Braided beard or hair','Unusual hair color','Nervous eye twitch','Distinctive nose','Distinctive posture (crooked or rigid)','Exceptionally beautiful','Exceptionally ugly')
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to generate appearance table"
                exit
            }
        }

        ## Generating the high ability table
        if (!($HighAbility)) {
            try {
                $HighAbilityTable = @('Strength','Dexterity','Constitution','Intelligence','Wisdom','Charisma')
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to generate high ability table"
                exit
            }
        }

        ## Generating the low ability table
        if (!($LowAbility)) {
            try {
                $LowAbilityTable = @('Strength','Dexterity','Constitution','Intelligence','Wisdom','Charisma')
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to generate low ability table"
                exit
            }
        }

        ## Generating a hash table with the description of high ability
        try {
            $HighAbilityDescription = @{
            'Strength' = 'Strong as an ox'
            'Dexterity' = 'Quick as a cat'
            'Constitution' = 'Tough as nails'
            'Intelligence' = 'Smart as a whip'
            'Wisdom' = 'Wise as an owl'
            'Charisma' = 'Charming as a snake'
            }
        }
        catch {
            Write-Verbose $Error[0]
            Write-Error "Failed to generate high ability description table"
            exit
        }

        ## Generating a hash table with the description of low ability
        try {
            $LowAbilityDescription = @{
            'Strength' = 'Weak as a kitten'
            'Dexterity' = 'Clumsy as a bear'
            'Constitution' = 'Sickly as a rat'
            'Intelligence' = 'Dumb as a rock'
            'Wisdom' = 'Dense as a brick'
            'Charisma' = 'Ugly as a toad'
            }
        }
        catch {
            Write-Verbose $Error[0]
            Write-Error "Failed to generate low ability description table"
            exit
        }

        ## Generating the talent table
        if (!($Talent)) {
            try {
                $TalentTable = @('Plays a musical instrument','Speaks several languages fluently','Unbelievably lucky','Perfect memory','Great with animals','Great with children','Great at solving puzzles','Great at one game','Great at impersonations','Draws beautifully','Paints beautifully','Sings beautifully','Drinks everyone under the table','Expert carpenter','Expert cook','Expert dart thrower and rock skipper','Expert juggler','Skilled actor and master of disguise','Skilled dancer','Knows thieves cant')
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to generate talent table"
                exit
            }
        }

        ## Generating the mannerism table
        if (!($Mannerism)) {
            try {
                $MannerismTable = @('Prone to singing, whistling, or humming quietly','Speaks in rhyme or some other peculiar way','Particularly low or high voice','Slurs words, lisps, or stutters','Enunciates overly clearly','Speaks loudly','Whispers','Uses flowery speech or long words','Frequently uses the wrong word','Uses colorful oaths and exclamations','Makes constant jokes or puns','Prone to predictions of doom','Fidgets','Squints','Stares into the distance','Chews something','Paces','Taps fingers','Bites fingernails','Twirls hair or tugs beard')
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to generate mannerism table"
                exit
            }
        }

        ## Generating the interaction table
        if (!($Interaction)) {
            try {
                $InteractionTable = @('Argumentative','Arrogant','Blustering','Rude','Curious','Friendly','Honest','Hot tempered','Irritable','Ponderous','Quiet','Suspicious')
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to generate interaction table"
                exit
            }
        }

        ## Generating the alignment table
        if (!($Alignment)) {
            try {
                $AlignmentTable = @('Lawful Good','Neutral Good','Chaotic Good','Lawful Neutral','True Neutral','Chaotic Neutral','Lawful Evil','Neutral Evil','Chaotic Evil')
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to generate alignment table"
                exit
            }
        }

        ## Generating the ideal table
        if (!($Ideal)) {
            try {
                $IdealTable = @('Beauty','Charity','Greater Good','Life','Respect','Self-Sacrifice','Domination','Greed','Might','Pain','Retribution','Slaughter','Change','Creativity','Freedom','Honesty','Independence','Knowledge','Live and Let Live','Moderation','Nation','People','Redemption','Self-Knowledge')
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to generate ideal table"
                exit
            }
        }

        ## Generating the bond table
        if (!($Bond)) {
            try {
                $BondTable = @('Dedicated to fulfilling a personal life goal','Protective of close family members','Protective of colleagues or compatriots','Loyal to a benefactor, patron, or employer','Captivated by a romantic interest','Drawn to a special place','Protective of a sentimental keepsake','Protective of a valuable possession','Out for revenge')
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to generate bond table"
                exit
            }
        }

        ## Generating the flaws and secrets table
        if (!($FlawsAndSecrets)) {
            try {
                $FlawsAndSecretsTable = @('Forbidden love or susceptibility to romance','Enjoys decadent pleasures','Arrogance','Envies another creatures possessions or station','Overpowering greed','Prone to rage','Has a powerful enemy','Prone to sudden suspicion','Shameful or scandalous history','Secret crime or misdeed','Possession of forbidden lore','Foolhardy bravery')
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to generate flaws and secrets table"
                exit
            }
        }

        # Generating dice rolls

        ## Doing a dice roll for race
        if (!($Race)) {
            Write-Verbose "Rolling a d9 for race"
            try {
                $RaceDiceRoll = Get-Random -Minimum 1 -Maximum 9 -ErrorAction Stop
                write-verbose "Rolled a d9, got $($RaceDiceRoll)"
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to roll for race"
                Exit
            }
        }
            
        else {
            Write-Verbose "Using the specified race of $($Race)"
        }

        ## Doing a dice roll for appearance
        if (!($Appearance)) {
            Write-Verbose "Rolling a d20 for appearance"
            try {
                $AppearanceDiceRoll = Get-Random -Minimum 1 -Maximum 20 -ErrorAction Stop
                write-verbose "Rolled a d20, got $($AppearanceDiceRoll)"
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to roll for appearance"
                Exit
            }
        }
            
        else {
            Write-Verbose "Using the specified appearance of $($Appearance)"
        }

        ## Doing a dice roll for high ability
        if (!($HighAbility)) {
            Write-Verbose "Rolling a d6 for high ability"
            try {
                $HighAbilityDiceRoll = Get-Random -Minimum 1 -Maximum 6 -ErrorAction Stop
                write-verbose "Rolled a d6, got $($HighAbilityDiceRoll)"
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to roll for high ability"
                Exit
            }
        }
            
        else {
            Write-Verbose "Using the specified high ability of $($HighAbility)"
        }

        ## Doing a dice roll for low ability
        if (!($LowAbility)) {
            Write-Verbose "Rolling a d6 for low ability"
            try {
                $LowAbilityDiceRoll = Get-Random -Minimum 1 -Maximum 6 -ErrorAction Stop
                write-verbose "Rolled a d6, got $($LowAbilityDiceRoll)"
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to roll for low ability"
                Exit
            }
        }
            
        else {
            Write-Verbose "Using the specified low ability of $($LowAbility)"
        }

        ## Doing a dice roll for talent
        if (!($Talent)) {
            Write-Verbose "Rolling a d20 for talent"
            try {
                $TalentDiceRoll = Get-Random -Minimum 1 -Maximum 20 -ErrorAction Stop
                write-verbose "Rolled a d20, got $($TalentDiceRoll)"
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to roll for talent"
                Exit
            }
        }
            
        else {
            Write-Verbose "Using the specified talent of $($Talent)"
        }

        ## Doing a dice roll for mannerism
        if (!($Mannerism)) {
            Write-Verbose "Rolling a d20 for mannerism"
            try {
                $MannerismDiceRoll = Get-Random -Minimum 1 -Maximum 20 -ErrorAction Stop
                write-verbose "Rolled a d20, got $($MannerismDiceRoll)"
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to roll for mannerism"
                Exit
            }
        }
            
        else {
            Write-Verbose "Using the specified mannerism of $($Mannerism)"
        }

        ## Doing a dice roll for interaction
        if (!($Interaction)) {
            Write-Verbose "Rolling a d12 for interaction"
            try {
                $InteractionDiceRoll = Get-Random -Minimum 1 -Maximum 12 -ErrorAction Stop
                write-verbose "Rolled a d12, got $($InteractionDiceRoll)"
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to roll for interaction"
                Exit
            }
        }
            
        else {
            Write-Verbose "Using the specified interaction of $($Interaction)"
        }

        ## Doing a dice roll for alignment
        if (!($Alignment)) {
            Write-Verbose "Rolling a d9 for alignment"
            try {
                $AlignmentDiceRoll = Get-Random -Minimum 1 -Maximum 9 -ErrorAction Stop
                write-verbose "Rolled a d9, got $($AlignmentDiceRoll)"
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to roll for alignment"
                Exit
            }
        }
            
        else {
            Write-Verbose "Using the specified alignment of $($Alignment)"
        }

        ## Doing a dice roll for ideal
        if (!($Ideal)) {
            Write-Verbose "Rolling a d25 for ideal"
            try {
                $IdealDiceRoll = Get-Random -Minimum 1 -Maximum 25 -ErrorAction Stop
                write-verbose "Rolled a d25, got $($IdealDiceRoll)"
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to roll for ideal"
                Exit
            }
        }
            
        else {
            Write-Verbose "Using the specified ideal of $($Ideal)"
        }

        ## Doing a dice roll for bond
        if (!($Bond)) {
            Write-Verbose "Rolling a d9 for bond"
            try {
                $BondDiceRoll = Get-Random -Minimum 1 -Maximum 9 -ErrorAction Stop
                write-verbose "Rolled a d9, got $($BondDiceRoll)"
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to roll for bond"
                Exit
            }
        }
            
        else {
            Write-Verbose "Using the specified bond of $($Bond)"
        }

        ## Doing a dice roll for flaws and secrets
        if (!($FlawsAndSecrets)) {
            Write-Verbose "Rolling a d12 for flaws and secrets"
            try {
                $FlawsAndSecretsDiceRoll = Get-Random -Minimum 1 -Maximum 12 -ErrorAction Stop
                write-verbose "Rolled a d12, got $($FlawsAndSecretsDiceRoll)"
            }
            catch {
                Write-Verbose $Error[0]
                Write-Error "Failed to roll for flaws and secrets"
                Exit
            }
        }
            
        else {
            Write-Verbose "Using the specified flaws and secrets of $($FlawsAndSecrets)"
        }

        # Grabbing high and low abilities
        try {
            if (!($HighAbility)) {
            $HighAbility = $HighAbilityTable[$HighAbilityDiceRoll - 1]
            }
        }
        catch {
            write-verbose $Error[0]
            Write-Error "Failed to grab high ability"
            Exit
        }

        try {
            if (!($LowAbility)) {
            $LowAbility = $LowAbilityTable[$LowAbilityDiceRoll - 1]
            }
        }
        catch {
            write-verbose $Error[0]
            Write-Error "Failed to grab low ability"
            Exit
        }

        # Putting together naming conventions
        

    }

    Process {

    }

    End {
	
    }
}