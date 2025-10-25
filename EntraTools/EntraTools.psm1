function New-UserPassword {
    $Adjectives = @("Ferocious", "Sabertoothed", "Maneating", "Bloodthirsty", "Vengeful", "Merciless", "Wrathful", "Hellbound", "Soulharvesting", "Crazed", "Blessed", "Flesheating", "Purple", "Excited")
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


	function Get-UserId {
        Param (
            [Parameter(Mandatory = $true)][String]$UPN
        )

		Try {
			$User = (Get-MgUser -Filter "UserPrincipalName eq '$UPN'").id
			if (-not ($User)) {
				throw
			} else {
                return $User
			}
		}
		Catch {
            return
		}
	}


function Add-UserGroups {
    param (
        [Parameter(Mandatory = $true)][String]$UPN,
        [Parameter(Mandatory = $false)][String[]]$Groups,
        [switch]$CSV
    )
		
    if ($CSV) {
        try {
            $FilePath = ".\Groups.csv"
            Test-Path -Path $FilePath -ErrorAction Stop
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

	$ValidatedGroups = @()
	foreach ($Group in $Groups) {
		Try {
			$Validated = (Get-MgGroup -Filter "DisplayName eq '$Group'" -ErrorAction Stop).id
			if ($Validated) {
                Write-Output "Group $Group validated with object ID $Validated"
				$ValidatedGroups += $Validated
			} else {
				throw
			}
		}
        Catch {
			Write-Warning "The group $Group does not exist, skipping..."
		}
	}


    Try {
        Write-Output "Fetching object ID for $UPN..."
		$User = Get-UserId -UPN $UPN
	}
	Catch {
		Write-Warning "Could not find $UPN in Entra ID, aborting"
		Return
	}


	foreach ($ValidatedGroup in $ValidatedGroups) {
		Try {
			$MembersBefore = Get-MgGroupMember -GroupId $ValidatedGroup -All -ErrorAction SilentlyContinue
			if (-not ($MembersBefore.Id -contains $User)) {
				Write-Output "Attemping to add $UPN to $ValidatedGroup"
				New-MgGroupMember -GroupId $ValidatedGroup -DirectoryObjectId $User -ErrorAction Stop
			} else {
				Write-Output "$UPN is already a member of $ValidatedGroup, skipping..."
                Continue
			}
        }
		Catch {
            Write-Warning "Action could not be performed for $ValidatedGroup"
			continue
        }

		Try {
            $MembersAfter = Get-MgGroupMember -GroupId $ValidatedGroup -All -ErrorAction SilentlyContinue
            if ($MembersAfter.Id -contains $User) {
				Write-Output "$UPN has been added to $ValidatedGroup"
			} else {
				throw
			}
        }
		Catch {
            Write-Output "Failed to retrieve validation of output"
        }
	}
}
Export-ModuleMember -Function New-EntraUser, Add-UserGroups, New-UserPassword
