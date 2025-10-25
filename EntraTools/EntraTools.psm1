function New-UserPassword {
    $Adjectives = @("Ferocious", "Sabertoothed", "Maneating", "Bloodthirsty", "Vengeful", "Merciless", "Wrathful", "Hellbound", "Soulharvesting", "Crazed", "Blessed", "Flesheating")
    $Nouns = @("Goldfish", "Froglet", "Bumblebee", "Pig", "Capybara", "Toad", "Rabbit", "Lamb", "Crab", "Shrimp", "Starfish")
    $Numbers = @("1", "2", "3", "4", "5", "6", "7", "8", "9", "0")
    $Characters = @("#", "%", "!", "?", "+", "\", "*", "$", "/")
    $RandomAdjective = Get-Random $Adjectives
    $RandomNoun = Get-Random $Nouns
    $RandomNumber = Get-Random $Numbers
    $RandomCharacter = Get-Random $Characters
    $RandomEasyToType = -join ($RandomAdjective, $RandomNoun, $RandomNumber, $RandomCharacter)
    return $RandomEasyToType
}

function New-EntraUser {
    param (
        [Parameter(Mandatory = $true)][String]$DN,
        [Parameter(Mandatory = $true)][String]$UPN
    )

    $RandomPassword = New-UserPassword
    $Passwordprofile = @{
        Password                             = $RandomPassword
        ForceChangePasswordNextSignIn        = $true
        ForceChangePasswordNextSignInWithMfa = $false
    }

    $UserSplat = @{
        DisplayName       = $DN
        MailNickname      = ($UPN.Split('@')[0])
        UserPrincipalName = $UPN
        GivenName         = ($DN.Split(' ')[0])
        Surname           = ($DN.Split(' ')[-1])
        PasswordProfile   = $Passwordprofile
        AccountEnabled    = $true
    }


    $NewUser = New-MgUser @UserSplat

    if ((Get-MgUser -Filter "UserPrincipalName eq '$UPN'").Id) {
        Write-Output "$DN added with username $UPN and password: $RandomPassword"
    } else {
        Write-Output "User $DN could not be added"
    }
    return $NewUser
}

function Add-UserGroups {
    param (
        [Parameter(Mandatory = $true)][String]$UPN,
        [Parameter(Mandatory = $false)][String[]]$Groups,
        [switch]$CSV
    )

    if ($CSV) {
        try {
            $FilePath = Test-Path -Path ".\Groups.csv" -ErrorAction Stop
        } catch {
            while ($true) {
                $UserSpecifiedPath = Read-Host "Specify path to csv file: "
                if (Test-Path -Path $UserSpecifiedPath) {
                    $Groups = Import-Csv -Path $UserSpecifiedPath -Delimiter ";" | Select-Object -ExpandProperty DisplayName
                    break
                } else {
                    Write-Warning "$UserSpecifiedPath not found. Try again, or press Ctrl C to exit the script"
                }
            }
        }
        $Groups = Import-Csv -Path $FilePath -Delimiter ";" | Select-Object -ExpandProperty DisplayName
    }

    foreach ($Group in $Groups) {
        $AddToGroup = (Get-MgGroup -Filter "DisplayName eq '$Group'").id
        $AddThisUser = (Get-MgUser -Filter "UserPrincipalName eq '$UPN'").id
        if ($AddToGroup) {
            try {
                Get-MgGroupMemberByRef -GroupId $AddToGroup -DirectoryObjectId $AddThisUser -ErrorAction Stop | Out-Null
                $Exists = $true
            } catch {
                $Exists = $false
            }
            if ($Exists) {
                continue
            }
            Write-Output "Adding $UPN to $Group"
            try {
                New-MgGroupMember -GroupId $AddToGroup -DirectoryObjectId $AddThisUser -ErrorAction Stop
            } catch {
                Write-Output "$UPN could not be added to $Group"
            }

            try {
                if (Get-MgGroupMember -GroupId $AddToGroup -filter "Id eq '$AddThisUser'" -ErrorAction Stop) {
					Write-Output "$UPN has been added to $Group"
				} else {
					Write-Output "$UPN has not been added to $Group"
				}
            } catch {
                Write-Output "Failed to retrieve validation of output"
            }

        } else {
            Write-Warning "The group $Group could not be found, skipping..."
            continue
        }
    }
}

Export-ModuleMember -Function New-EntraUser, Add-UserGroups, New-UserPassword
