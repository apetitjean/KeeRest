$ErrorActionPreference = 'Stop'
function Connect-KeepassDB {
    param(
        [Parameter(Mandatory=$false)]
        [String]$KDBXDatabasePath = 'C:\Users\Arnaud\Documents\KeePass\Database1.kdbx',
  
        [Parameter(Mandatory=$true)]
        [SecureString]$KDBXPassword
    )
  
    $path = "C:\Program Files (x86)\KeePass Password Safe 2"
    [Reflection.Assembly]::LoadFile("$path\KeePass.exe") | Out-Null
    [Reflection.Assembly]::LoadFile("$path\KeePass.XmlSerializers.dll") | Out-Null

    try {
        $Kdbx = New-Object KeePassLib.PwDatabase
        $IoConnectionInfo =  New-Object KeePassLib.Serialization.IOConnectionInfo
        $IoConnectionInfo.Path = $KDBXDatabasePath

        $Key = New-Object KeePassLib.Keys.CompositeKey
        $bstr = [System.Runtime.InteropServices.marshal]::SecureStringToBSTR($KDBXPassword)
        $clearPassword = [System.Runtime.InteropServices.marshal]::PtrToStringBSTR($bstr)
        $Key.AddUserKey(( New-Object KeePassLib.Keys.KcpPassword($clearPassword)))
        $Kdbx.Open($IoConnectionInfo, $Key, $null)
        $Kdbx
    }
    catch {
        throw $_
    }
}

function Lock-KeepassDB {
	param(
		[Parameter(Mandatory=$true)]
		[KeePassLib.PwDatabase]$KDBXDatabase
	)
    
    $KDBXDatabase.Close() | Out-Null
	
}

function Get-KeepassEntry {
    param(
      [Parameter(Mandatory=$true)]
      [KeePassLib.PwDatabase]$KDBXDatabase,

      [Parameter(Mandatory=$false)]
      [String]$FieldFilter = 'Title',

      [Parameter(Mandatory=$false)]
      [String]$ValueFilter = '*'
    )
    
    $Items = $KDBXDatabase.RootGroup.GetObjects($true,$true) | Where-Object { 
        $_.Strings.ReadSafe($FieldFilter) -match $ValueFilter
    }
    foreach ($Item in $Items) {
        [PSCustomObject]@{
            Title                = $Item.Strings.ReadSafe("Title")
            UserName             = $Item.Strings.ReadSafe("UserName")
            Password             = $Item.Strings.ReadSafe("Password")
            Tags                 = $Item.Tags
            LastModificationTime = $Item.LastModificationTime
            }
    }    	 
}

function Start-KeepassRandomGenerator {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false)]
        [Int] $Port = 8000,
        
        [Parameter(Mandatory=$false)]
        [Int] $DefaultPasswordSize = 12
    )

    # Bidouille pour pouvoir passer une variable en dehors du scope dans New-PolarisRoute
    $script:DefaultPwdSize = $DefaultPasswordSize
    New-PolarisRoute -Path '/randomPasswordGenerator/:size?' -Method GET -ScriptBlock {
        if( $Request.Parameters.size ){
           [Int]$Size = $Request.Parameters.Size
        }
        else {
           [Int]$Size = $script:DefaultPwdSize
        }
    
        $password = (1..$Size | ForEach-Object { [Char](Get-Random -Minimum 33 -Maximum 127)}) -join ''
        $Response.Send( (@{ password = $password } | ConvertTo-Json) )
    }     
    Start-Polaris -Port $Port
}

function Start-KeepassRestService {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false)]
        [Int] $Port = 8080,
        [Parameter(Mandatory=$true)]
        [SecureString] $KDBXPassword,
        [Parameter(Mandatory=$true)]
        [String] $KDBXDatabase
    )

    $script:db = Connect-KeepassDB -Password $KDBXPassword -DbPath $KDBXDatabase

    New-PolarisRoute -Method GET -Path '/keepass/title' -Scriptblock {
        $result = Get-KeepassEntry -Database $script:db | ConvertTo-Json 
        $response.send($result)
    }
    
    New-PolarisRoute -Method GET -Path '/keepass/title/:title' -ScriptBlock {
        $title = $Request.Parameters.title
        $result = Get-KeepassEntry -Database $script:db -EntryTitleFilter $title | ConvertTo-Json 
        $response.send($result)
    }
    Start-Polaris -Port $Port
}
