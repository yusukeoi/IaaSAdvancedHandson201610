$subscriptionName = "Hybrid ID"

$storageAccountName = "test20160928"

$systemRG = "yooiaad01c"

$vmName = "test20160928"

# Size of the virtual machine. See the VM sizes documentation for more information: https://azure.microsoft.com/documentation/articles/virtual-machines-windows-sizes/
$vmSize = "Standard_D1_v2"

# Computer name for the VM
$hostName = "test20160928"

# Name of the disk that holds the OS
$osDiskName = $vmName + "osdisk"

$location = "eastasia"

$vnetRG = "aad01-Migrated"
$vnetName = "aad01"

$pipName = $vmName + "pip"
$nicName = $vmName + "nic"

$privateIP = "192.168.0.90"

$storageAccountName = "yooiaad01c"

$imageURI = "https://yooiaad01c.blob.core.windows.net/vhds/template01201672915257.vhd"


===================
Login-AzureRmAccount

Select-AzureRmSubscription -SubscriptionName $subscriptionName


$windowsAdmin = Get-Credential

$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $vnetRG -Name $vnetName  
$subnet = $vnet.Subnets[0].Id

$pip = New-AzureRmPublicIpAddress -Name $pipName -ResourceGroupName $systemRG -Location $location -AllocationMethod Dynamic
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $systemRG -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -PrivateIpAddress $privateIP

$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $systemRG -Name $storageAccountName

#Set the VM name and size
#Use "Get-Help New-AzureRmVMConfig" to know the available options for -VMsize
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize

#Set the Windows operating system configuration and add the NIC
$vm = Set-AzureRmVMOperatingSystem -VM $vmConfig -Windows -ComputerName $hostName -Credential $windowsAdmin -ProvisionVMAgent -EnableAutoUpdate
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

#Create the OS disk URI
$osDiskUri = '{0}vhds/{1}-{2}.vhd' -f $storageAccount.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $osDiskName

#Configure the OS disk to be created from the image (-CreateOption fromImage), and give the URL of the uploaded image VHD for the -SourceImageUri parameter
#You set this variable when you uploaded the VHD
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $osDiskUri -CreateOption fromImage -SourceImageUri $imageURI -Windows
    
$tags += @{Name="billingId";Value="20018"}


# Set-AzureRmResource -ResourceGroupName $systemRG -Name $vmName -ResourceType "Microsoft.Compute/VirtualMachines" -Tag $tags

#Create the new VM
New-AzureRmVM -ResourceGroupName $systemRG -Location $location -VM $vm


