Get-Module KeeRest | Remove-Module -Force
Import-Module $PSScriptRoot\KeeRest.psm1 -Force
# https://devblogs.microsoft.com/scripting/testing-script-modules-with-pester/

Describe 'Connect-KeepassDB' {
    $DBObj = Connect-KeepassDB -KDBXDatabasePath "$PSScriptRoot\Tests\TestDatabase.kdbx" -KDBXPassword (ConvertTo-SecureString "KeeRest_Rocks!" -AsPlainText -Force)   
    Context 'Connects' {         
        it 'connects to the DB' {
            $DBObj.GetType().Name | should be "PwDatabase"
            $DBObj.IsOpen | should be $True
        }
    }
    
    Lock-KeepassDB -KDBXDatabase $DBObj
    Context 'Disconnects' {
        it 'Disconnects from the DB' {
            $DBObj.IsOpen | should be $false
        }
    }
 }

 Describe 'Get-KeepassEntry' {
    Context 'Communicates with the KDBX' {
        $DBObj = Connect-KeepassDB -KDBXDatabasePath "$PSScriptRoot\Tests\TestDatabase.kdbx" -KDBXPassword (ConvertTo-SecureString "KeeRest_Rocks!" -AsPlainText -Force)
        $info = Get-KeepassEntry -KDBXDatabase $DBObj -ValueFilter "Arnaud"
        it 'Get and entry informations correctly' {
            $info.Title | should BeExactly "Arnaud"
            $info.Password  | should BeExactly "IB6WkecQ2wWm9VaLgksq"
            $info.UserName  | should BeExactly "apetitjean"
        }
        $info = Get-KeepassEntry -KDBXDatabase $DBObj -FieldFilter 'Title' -ValueFilter "^Ar"
        it 'returns multiple entries correctly' {
            $info.Length  | should Be 2
        }
     }
 }