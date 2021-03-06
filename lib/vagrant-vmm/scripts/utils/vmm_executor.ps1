#
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "manage_credentials.ps1"))

# execute script block for VMM
function execute($block, $vmm_server_address, $proxy_server_address)
{
  $vmm_credential = Get-Creds $vmm_server_address "Credentials for VMM server: $vmm_server_address"
  #
  $init_vmm_block = {
    try {
      ipmo 'C:\Program Files\Microsoft System Center 2012 R2\Virtual Machine Manager\bin\psModules\virtualmachinemanager'
    } catch {
      write-error 'You need to install Virtual Machine Manager R2 client first.'
      throw $_.Exception
    }
    #
    $vmmServer = Get-VMMServer -ComputerName $using:vmm_server_address -Credential $using:vmm_credential
  }
  $block_to_run = [ScriptBlock]::Create($init_vmm_block.ToString() + $block.ToString())
  #
  if ( $proxy_server_address -eq $null )
  {
    $res = $(Start-Job $block_to_run | Wait-Job | Receive-Job)
  } else {
    $proxy_credential = Get-Creds $proxy_server_address "Credentials for proxy server: $proxy_server_address"
    $res = invoke-command -ComputerName $proxy_server_address -Credential $proxy_credential -ScriptBlock $block_to_run
  }
  return $res
}
