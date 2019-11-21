Get-Module KeeRest | Remove-Module -Force
Import-Module $PSScriptRoot\KeeRest.psm1 -Force
# https://devblogs.microsoft.com/scripting/testing-script-modules-with-pester/

Describe 'Connect-KeepassDB' {

    Context 'Connects' {
        $DBObj = Connect-KeepassDB -DbPath ".\Tests\TestDatabase.kdbx" -Password (ConvertTo-SecureString "KeeRest_Rocks!" -AsPlainText -Force)

        it 'connects to the DB' {
            $DBObj.GetType().Name | should be "PwDatabase"
            $DBObj.IsOpen | should be $True
        }
    }
    Context 'Disconnects' {
        Lock-KeepassDB -Database $DBObj
        it 'Disconnects from the DB' {
            $DBObj.IsOpen | should be $false
        }
    }
 }

 Describe 'Get-KeepassEntry' {

    Context 'Communicates with the KDBX' {
        $DBObj = Connect-KeepassDB -DbPath ".\Tests\TestDatabase.kdbx" -Password (ConvertTo-SecureString "KeeRest_Rocks!" -AsPlainText -Force)
        $info = Get-KeepassEntry -Database $DBObj -EntryTitleFilter "Arnaud"
        it 'Get and entry informations correctly' {
            $info.Title | should BeExactly "Arnaud"
            $info.Password  | should BeExactly "IB6WkecQ2wWm9VaLgksq"
            $info.UserName  | should BeExactly "apetitjean"
        }
        $info = Get-KeepassEntry -Database $DBObj -EntryTitleFilter "^Ar"
        it 'returns multiple entries correctly' {
            $info.Length  | should Be 2
        }
     }
 }