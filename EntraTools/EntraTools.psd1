@{
    RootModule           = 'EntraTools.psm1'
    ModuleVersion        = '1.0.0'
    GUID                 = 'c997d099-f4b8-4747-8d47-ce15e1ab3851'

    Author               = 'Daniel Berg'
    Description          = 'Toolkit to create Entra ID users, generate OTP or add user group membership'

    PowerShellVersion    = '7.4.0'

    # Exporterade funktioner
    FunctionsToExport    = @(
        'New-UserPassword',
        'New-EntraUser',
        'Add-UserGroups'
    )

    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()

    FileList             = @(
        'EntraTools.psm1'
    )

    HelpInfoURI          = 'https://github.com/endanistan/MacGraphToolKits/EntraTools'
    LicenseUri           = 'https://opensource.org/licenses/MIT'

    PrivateData          = @{
        PSData = @{
            Tags         = @('Entra', 'AzureAD', 'Automation', 'UserManagement')
            ProjectUri   = 'https://github.com/endanistan/MacGraphToolKits/EntraTools'
            ReleaseNotes = 'Initial release with user creation, password generation, and group assignment.'
        }
    }
}

