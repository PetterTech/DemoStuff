function verb-noun
    {
    <#
    .Synopsis
    Short description
    .Description
    Long description
    .Parameter Parameter1
    Info about Parameter1
    .Example
    verb-noun
    Describe what verb-noun does
    .Example
    verb-noun -Parameter1 something
    Describe what verb-noun -Parameter1 something does
    .Link
    https://github.com/PetterTech/DemoStuff
    #>
        [CmdletBinding()] 
            Param (
                [Parameter(Mandatory=$True,Position=0,HelpMessage='Lorem Ipsum')][string]$Mandatoryparameter,
                [string]$Presetparameter = 'value',
                [string]$StringParameter,
                [ValidateScript({
                    Get-MsolPartnerContract -DomainName $_
                    }
                    )][string]$ScriptValidatedParameter,
                [Parameter][ValidateSet('Normal','Fighting','Flying')][string]$ParameterFromSet,
                [int]$IntegerParameter,
                $WeeklyTypedParameter,
                [switch]$Switch
                  )
    Begin {
	
    }

    Process {
        code
    }

    End {
	
    }
}