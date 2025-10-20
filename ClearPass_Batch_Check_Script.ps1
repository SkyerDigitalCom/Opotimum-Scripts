# ClearPass BMC Owned Device Attribute Checker
# This script verifies if devices have the "BMC Owned Device" attribute in HPE Aruba ClearPass

#Requires -Version 5.1

<#
.SYNOPSIS
    Verifies BMC Owned Device attribute for a list of hostnames in ClearPass
.DESCRIPTION
    Reads a list of computer names and checks each one in ClearPass web UI for the BMC Owned Device attribute
.PARAMETER DeviceListPath
    Path to text file containing device names (one per line)
.PARAMETER OutputPath
    Path for the results CSV file
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$DeviceListPath,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "ClearPass_Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv",
    
    [Parameter(Mandatory=$true)]
    [string]$ClearPassURL = "https://10.153.11.60",
    
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$true)]
    [SecureString]$Password
)

# Install Selenium module if not present
if (-not (Get-Module -ListAvailable -Name Selenium)) {
    Write-Host "Installing Selenium PowerShell module..." -ForegroundColor Yellow
    Install-Module -Name Selenium -Force -Scope CurrentUser
}

Import-Module Selenium

# Function to convert SecureString to plain text
function ConvertFrom-SecureString-ToPlainText {
    param([SecureString]$SecureString)
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    $PlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    return $PlainText
}

# Initialize results array
$results = @()

try {
    Write-Host "Starting ClearPass device verification..." -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    
    # Read device list
    if (-not (Test-Path $DeviceListPath)) {
        throw "Device list file not found: $DeviceListPath"
    }
    
    $devices = Get-Content $DeviceListPath | Where-Object { $_.Trim() -ne "" }
    Write-Host "Found $($devices.Count) devices to check" -ForegroundColor Green
    
    # Setup Chrome options for self-signed certificates
    $chromeOptions = New-Object OpenQA.Selenium.Chrome.ChromeOptions
    $chromeOptions.AddArgument('--ignore-certificate-errors')
    $chromeOptions.AddArgument('--ignore-ssl-errors')
    $chromeOptions.AddArgument('--disable-gpu')
    $chromeOptions.AddArgument('--no-sandbox')
    $chromeOptions.AddArgument('--disable-dev-shm-usage')
    # Comment out the next line if you want to see the browser
    $chromeOptions.AddArgument('--headless')
    
    Write-Host "Launching Chrome WebDriver..." -ForegroundColor Yellow
    $driver = New-Object OpenQA.Selenium.Chrome.ChromeDriver($chromeOptions)
    $driver.Manage().Timeouts().ImplicitWait = [TimeSpan]::FromSeconds(10)
    
    # Navigate to ClearPass login
    Write-Host "Navigating to ClearPass..." -ForegroundColor Yellow
    $driver.Navigate().GoToUrl($ClearPassURL)
    Start-Sleep -Seconds 3
    
    # Login
    Write-Host "Logging in..." -ForegroundColor Yellow
    $plainPassword = ConvertFrom-SecureString-ToPlainText -SecureString $Password
    
    # Find and fill login form (adjust selectors based on actual ClearPass login page)
    try {
        $usernameField = $driver.FindElementById("username")
        $usernameField.SendKeys($Username)
        
        $passwordField = $driver.FindElementById("password")
        $passwordField.SendKeys($plainPassword)
        
        $loginButton = $driver.FindElementByXPath("//button[@type='submit' or @type='button']")
        $loginButton.Click()
        
        Start-Sleep -Seconds 5
        Write-Host "Login successful!" -ForegroundColor Green
    }
    catch {
        Write-Host "Login failed. Trying alternative login selectors..." -ForegroundColor Yellow
        # Alternative login attempt
        $usernameField = $driver.FindElementByName("username")
        $usernameField.SendKeys($Username)
        
        $passwordField = $driver.FindElementByName("password")
        $passwordField.SendKeys($plainPassword)
        
        $passwordField.SendKeys([OpenQA.Selenium.Keys]::Enter)
        Start-Sleep -Seconds 5
    }
    
    # Navigate to endpoints page
    Write-Host "Navigating to endpoints page..." -ForegroundColor Yellow
    $driver.Navigate().GoToUrl("$ClearPassURL/tips/tipsContent.action#tipsEndpoints.action")
    Start-Sleep -Seconds 5
    
    # Process each device
    $counter = 0
    foreach ($deviceName in $devices) {
        $counter++
        Write-Host "[$counter/$($devices.Count)] Checking: $deviceName" -ForegroundColor Cyan
        
        $result = [PSCustomObject]@{
            DeviceName = $deviceName
            BMCOwnedDevice = "Not Found"
            Status = "Unknown"
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        try {
            # Find and clear search box
            $searchBox = $driver.FindElementById("filterField-0")
            $searchBox.Clear()
            $searchBox.SendKeys($deviceName)
            $searchBox.SendKeys([OpenQA.Selenium.Keys]::Enter)
            
            Start-Sleep -Seconds 3
            
            # Check if device found - look for result row
            try {
                # Try to click on the first result to open device details
                $firstResult = $driver.FindElementByXPath("//tr[contains(@class, 'dgrid-row')]")
                $firstResult.Click()
                Start-Sleep -Seconds 2
                
                # Look for the BMC Owned Device attribute
                try {
                    $bmcElement = $driver.FindElementById("tips_endpoint_editor_edit_r0_c1")
                    if ($bmcElement.Text -eq "BMC Owned Device") {
                        $result.BMCOwnedDevice = "Yes"
                        $result.Status = "Found - Has BMC Attribute"
                        Write-Host "  ✓ BMC Owned Device attribute FOUND" -ForegroundColor Green
                    }
                    else {
                        $result.BMCOwnedDevice = "No"
                        $result.Status = "Found - Missing BMC Attribute"
                        Write-Host "  ✗ BMC Owned Device attribute NOT FOUND" -ForegroundColor Yellow
                    }
                }
                catch {
                    # Check alternative locations or table rows for the attribute
                    try {
                        $attributeExists = $driver.FindElementsByXPath("//*[contains(text(), 'BMC Owned Device')]")
                        if ($attributeExists.Count -gt 0) {
                            $result.BMCOwnedDevice = "Yes"
                            $result.Status = "Found - Has BMC Attribute"
                            Write-Host "  ✓ BMC Owned Device attribute FOUND (alternative location)" -ForegroundColor Green
                        }
                        else {
                            $result.BMCOwnedDevice = "No"
                            $result.Status = "Found - Missing BMC Attribute"
                            Write-Host "  ✗ BMC Owned Device attribute NOT FOUND" -ForegroundColor Yellow
                        }
                    }
                    catch {
                        $result.BMCOwnedDevice = "No"
                        $result.Status = "Found - Missing BMC Attribute"
                        Write-Host "  ✗ BMC Owned Device attribute NOT FOUND" -ForegroundColor Yellow
                    }
                }
                
                # Navigate back to search
                $driver.Navigate().GoToUrl("$ClearPassURL/tips/tipsContent.action#tipsEndpoints.action")
                Start-Sleep -Seconds 2
            }
            catch {
                $result.Status = "Device Not Found in ClearPass"
                Write-Host "  ! Device not found in ClearPass" -ForegroundColor Red
            }
        }
        catch {
            $result.Status = "Error: $($_.Exception.Message)"
            Write-Host "  ! Error checking device: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        $results += $result
    }
    
    # Export results
    Write-Host "`n================================================" -ForegroundColor Cyan
    Write-Host "Exporting results to: $OutputPath" -ForegroundColor Green
    $results | Export-Csv -Path $OutputPath -NoTypeInformation
    
    # Display summary
    $foundWithBMC = ($results | Where-Object { $_.BMCOwnedDevice -eq "Yes" }).Count
    $foundWithoutBMC = ($results | Where-Object { $_.BMCOwnedDevice -eq "No" }).Count
    $notFound = ($results | Where-Object { $_.Status -like "*Not Found*" }).Count
    
    Write-Host "`nSUMMARY:" -ForegroundColor Cyan
    Write-Host "  Total Devices Checked: $($devices.Count)" -ForegroundColor White
    Write-Host "  With BMC Owned Device: $foundWithBMC" -ForegroundColor Green
    Write-Host "  Without BMC Owned Device: $foundWithoutBMC" -ForegroundColor Yellow
    Write-Host "  Not Found in ClearPass: $notFound" -ForegroundColor Red
    Write-Host "`nResults saved to: $OutputPath" -ForegroundColor Green
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
finally {
    # Cleanup
    if ($driver) {
        Write-Host "`nClosing browser..." -ForegroundColor Yellow
        $driver.Quit()
        $driver.Dispose()
    }
}

Write-Host "`nScript completed!" -ForegroundColor Green