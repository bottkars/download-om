
<#PSScriptInfo

.VERSION 1.1

.GUID 396c7684-3871-45e1-9290-3b8ac013a59c

.AUTHOR Kbott@pivotal.io

.COMPANYNAME 

.COPYRIGHT 

.TAGS 

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


#>

<# 

.DESCRIPTION 
 Download Pivotal Operations Manager CLI Releases from GitHub 

#> 
# This helper script downloads an available om Version
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({
        write-verbose $_
        if(-Not ( split-path -LiteralPath $_ | Test-Path ) ){
            throw "Folder does not exist or is not a container"
        }
        return $true
    })]
        $DownloadDir
)
DynamicParam {
    function get-releases {
        $request = Invoke-WebRequest -UseBasicParsing -Uri https://github.com/pivotal-cf/om/releases
        $windowsRelease = $request.links | where href -Match om-windows
        $releases = $windowsRelease | ForEach-Object {($_.href -split "/")[-2]}
        write-verbose "getting releases"
        Write-Output $releases
    }
    function New-DynamicParam {
        param(

            [string]
            $Name,

            [string[]]
            $ValidateSet,

            [switch]
            $Mandatory,

            [string]
            $ParameterSetName = "__AllParameterSets",

            [int]
            $Position,

            [switch]
            $ValueFromPipelineByPropertyName,

            [string]
            $HelpMessage,

            [validatescript( {
                    if (-not ( $_ -is [System.Management.Automation.RuntimeDefinedParameterDictionary] -or -not $_) ) {
                        Throw "DPDictionary must be a System.Management.Automation.RuntimeDefinedParameterDictionary object, or not exist"
                    }
                    $True
                })]
            $DPDictionary = $false

        )
        #Create attribute object, add attributes, add to collection
        $ParamAttr = New-Object System.Management.Automation.ParameterAttribute
        $ParamAttr.ParameterSetName = $ParameterSetName
        if ($mandatory) {
            $ParamAttr.Mandatory = $True
        }
        if ($Position -ne $null) {
            $ParamAttr.Position = $Position
        }
        if ($ValueFromPipelineByPropertyName) {
            $ParamAttr.ValueFromPipelineByPropertyName = $True
        }
        if ($HelpMessage) {
            $ParamAttr.HelpMessage = $HelpMessage
        }

        $AttributeCollection = New-Object 'Collections.ObjectModel.Collection[System.Attribute]'
        $AttributeCollection.Add($ParamAttr)

        #param validation set if specified
        if ($ValidateSet) {
            $ParamOptions = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $ValidateSet
            $AttributeCollection.Add($ParamOptions)
        }


        #Create the dynamic parameter
        $Parameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList @($Name, [string], $AttributeCollection)

        #Add the dynamic parameter to an existing dynamic parameter dictionary, or create the dictionary and add it
        if ($DPDictionary) {
            $DPDictionary.Add($Name, $Parameter)
        }
        else {
            $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $Dictionary.Add($Name, $Parameter)
            $Dictionary
        }
    }
    $releases = get-releases
    $releaselist = @()
    foreach ($release in $releases ) {
        Write-Verbose $release
        $releaselist += $release


    }
    New-DynamicParam -Name OmRelease -ValidateSet $releaselist  -Mandatory
}
Begin {
    foreach ($param in $PSBoundParameters.Keys) {
        if (-not ( Get-Variable -name $param -scope 0 -ErrorAction SilentlyContinue ) -and "Verbose", "Debug" -notcontains $param ) {
            New-Variable -Name $Param -Value $PSBoundParameters.$param -Description DynParam
            Write-Verbose "Adding variable for dynamic parameter '$param' with value '$($PSBoundParameters.$param)'"
        }
    }

}

Process {
    write-host "Downloading release $OmRelease"
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
    $Outfile = "$DownloadDir/om.exe"
    Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/pivotal-cf/om/releases/download/$OmRelease/om-windows.exe" -OutFile $Outfile
    Unblock-File $Outfile
    
}
end {
    $object = New-Object psobject
    $object  | Add-Member -MemberType NoteProperty -Name Path -Value $Outfile
    $object  | Add-Member -MemberType NoteProperty -Name Version -Value (.$Outfile -version)
    Write-Output $object
}




