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

Describe 'New-KeepassEntry and Remove-KeepassEntry' {
    Context 'Creates new entry in the KDBX' {
        $DBObj = Connect-KeepassDB -KDBXDatabasePath "$PSScriptRoot\Tests\TestDatabase.kdbx" -KDBXPassword (ConvertTo-SecureString "KeeRest_Rocks!" -AsPlainText -Force)
        $NewEntryInfos = @{
            Title = "TesTPesterEntry"
            UserName = "Pester"
            Password = "Pester-T3sts_Rocks!"
            URL = 'https://github.com/apetitjean/KeeRest'
            Notes = "Thumb up if you found this searching GitHub for Passw0rd!"
            Tags = "Test, Pester, Keerest"
        }
        New-KeepassEntry -KDBXDatabase $DBObj -EntryInfos $NewEntryInfos
        $createdEntry = Get-KeepassEntry -KDBXDatabase $DBObj -FieldFilter 'UserName' -ValueFilter "Pester"
        Lock-KeepassDB -KDBXDatabase $DBObj
        $DBObj = Connect-KeepassDB -KDBXDatabasePath "$PSScriptRoot\Tests\TestDatabase.kdbx" -KDBXPassword (ConvertTo-SecureString "KeeRest_Rocks!" -AsPlainText -Force)
        it 'Create a new entry correctly' {
            $createdEntry.Title | Should BeExactly $NewEntryInfos.Title
            $createdEntry.UserName | Should BeExactly $NewEntryInfos.UserName
            $createdEntry.Password | Should BeExactly $NewEntryInfos.Password
            $createdEntry.URL  | Should BeExactly $NewEntryInfos.URL
            $createdEntry.Note  | Should BeExactly $NewEntryInfos.Note
            #TODO tags
        }
        $Uuid = $createdEntry.Uuid
        Remove-KeeRestEntry -KDBXDatabase $DBObj -EntryUuid $Uuid
        Lock-KeepassDB -KDBXDatabase $DBObj
        $DBObj = Connect-KeepassDB -KDBXDatabasePath "$PSScriptRoot\Tests\TestDatabase.kdbx" -KDBXPassword (ConvertTo-SecureString "KeeRest_Rocks!" -AsPlainText -Force)
        $DeletedEntry = Get-KeepassEntry -KDBXDatabase $DBObj -FieldFilter 'UserName' -ValueFilter "Pester"
        it 'returns multiple entries correctly' {
            $DeletedEntry | should Be $null
        }
    }
}