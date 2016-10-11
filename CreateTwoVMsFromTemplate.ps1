$subscriptionName = "yooi demo"

# VMイメージが配置されているコンテナ (VMイメージのURLの最後の "/" の前まで)
$source = "https://yooiaad01d.blob.core.windows.net/vhds"
# VMイメージ名 (VMイメージのURLの最後の "/" の後ろ)
$imageVHD = "template01201672915257.vhd"

# 新規作成するストレージアカウントのリソースグループ名
$vmRG = "aztr99rg" #要変更

# 新規作成するストレージアカウント名
$webStorageAccountName = "aztr99st" #要変更
# 新規作成するストレージアカウントの種類
$storageType = "Standard_LRS"
# 新規作成するストレージアカウントの場所
$location = "japanwest"

# 仮想ネットワーク(作成済み)
$vnetName = "autohaVNETsqszg"
$vnetRG = "yooialwayson"

# サブネット
$subnetName1 = "Subnet-99a"  #要変更
$subnetName2 = "Subnet-99b"  #要変更

# 可用性セット
$availabilitySetName = "aztr99as"  #要変更

### Azure VM1 ###

# Azure VM名
$vmName1 = "aztr99vm01"  #要変更
# (OS上の)コンピュータ名
$computerName1 = "aztr99vm01"  #要変更
# VMの内部IP
$privateIP1 = "10.0.99.5"  #要変更

### Azure VM2 ###

# Azure VM名
$vmName2 = "aztr99vm02"  #要変更
# (OS上の)コンピュータ名
$computerName2 = "aztr99vm02"  #要変更
# VMの内部IP
$privateIP2 = "10.0.100.5"  #要変更

# VMサイズ https://azure.microsoft.com/documentation/articles/virtual-machines-windows-sizes/
$vmSize = "Standard_A1"

####################################################################

Select-AzureRmSubscription -SubscriptionName $subscriptionName

# 新規ストレージアカウントおよびリソースグループの作成
New-AzureRmResourceGroup -Name $vmRG -Location $location
$webStorageAccount = New-AzureRmStorageAccount -ResourceGroupName $vmRG -Name $webStorageAccountName -Location $location -SkuName $storageType -EnableEncryptionService Blob

# 新ストレージアカウントのURL
$dest = $webStorageAccount.PrimaryEndpoints.Blob + "vhds"

# 新旧ストレージアカウントのアクセスキー取得
$sourceKey = "+1gKRK9GDyDoLRzJcCk9z9qxDTDTcMqD/1NiVSkrIvFKjipCra62XmZVqM2gJ3BmaRgUvD6GCCqFitCA49603g=="
$destKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $vmRG -Name $webStorageAccountName)[0].Value

# 新規ストレージアカウントのへのVMイメージのコピー
& 'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe' /Source:$source /Dest:$dest /SourceKey:$sourceKey /DestKey:$destKey /Pattern:$imageVHD

$imageURI = $webStorageAccount.PrimaryEndpoints.Blob + "vhds/" + $imageVHD

####################################################################

$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $vnetRG -Name $vnetName
$subnet1 = Get-AzureRmVirtualNetworkSubnetConfig -Name $subnetName1 -VirtualNetwork $vnet
$subnet2 = Get-AzureRmVirtualNetworkSubnetConfig -Name $subnetName2 -VirtualNetwork $vnet

####################################################################

# Windows OS上の管理者IDおよびパスワードの入力
$windowsAdmin = Get-Credential

####################################################################

# 可用性セット
$as = New-AzureRmAvailabilitySet -ResourceGroupName $vmRG -Name $availabilitySetName -Location $location

####################################################################

### Azure VM1 ###

# 外部IPの作成 (外部IPを付与しない場合は以下2行をコメントアウトすること)
$pipName1 = $vmName1 + "pip"
$pip1 = New-AzureRmPublicIpAddress -Name $pipName1 -ResourceGroupName $vmRG -Location $location -AllocationMethod Dynamic

# 仮想NICの作成および内部IPの指定
$nicName1 = $vmName1 + "nic"
$nic1 = New-AzureRmNetworkInterface -Name $nicName1 -ResourceGroupName $vmRG -Location $location -SubnetId $subnet1.Id -PublicIpAddressId $pip1.Id -PrivateIpAddress $privateIP1

# VMの作成
$vmConfig1 = New-AzureRmVMConfig -VMName $vmName1 -VMSize $vmSize -AvailabilitySetId $as.Id
$vm1 = Set-AzureRmVMOperatingSystem -VM $vmConfig1 -Windows -ComputerName $computerName1 -Credential $windowsAdmin -ProvisionVMAgent -EnableAutoUpdate
$vm1 = Add-AzureRmVMNetworkInterface -VM $vm1 -Id $nic1.Id
$osDiskName1 = $vmName1 + "osdisk"
$osDiskUri1 = '{0}vhds/{1}-{2}.vhd' -f $webStorageAccount.PrimaryEndpoints.Blob.ToString(), $vmName1.ToLower(), $osDiskName1
$vm1 = Set-AzureRmVMOSDisk -VM $vm1 -Name $osDiskName1 -VhdUri $osDiskUri1 -CreateOption fromImage -SourceImageUri $imageURI -Windows
New-AzureRmVM -ResourceGroupName $vmRG -Location $location -VM $vm1

####################################################################

### Azure VM2 ###

# 外部IPの作成 (外部IPを付与しない場合は以下2行をコメントアウトすること)
$pipName2 = $vmName2 + "pip"
$pip2 = New-AzureRmPublicIpAddress -Name $pipName2 -ResourceGroupName $vmRG -Location $location -AllocationMethod Dynamic

# 仮想NICの作成および内部IPの指定
$nicName2 = $vmName2 + "nic"
$nic2 = New-AzureRmNetworkInterface -Name $nicName2 -ResourceGroupName $vmRG -Location $location -SubnetId $subnet2.Id -PublicIpAddressId $pip2.Id -PrivateIpAddress $privateIP2

# VMの作成
$vmConfig2 = New-AzureRmVMConfig -VMName $vmName2 -VMSize $vmSize -AvailabilitySetId $as.Id
$vm2 = Set-AzureRmVMOperatingSystem -VM $vmConfig2 -Windows -ComputerName $computerName2 -Credential $windowsAdmin -ProvisionVMAgent -EnableAutoUpdate
$vm2 = Add-AzureRmVMNetworkInterface -VM $vm2 -Id $nic2.Id
$osDiskName2 = $vmName2 + "osdisk"
$osDiskUri2 = '{0}vhds/{1}-{2}.vhd' -f $webStorageAccount.PrimaryEndpoints.Blob.ToString(), $vmName2.ToLower(), $osDiskName2
$vm2 = Set-AzureRmVMOSDisk -VM $vm2 -Name $osDiskName2 -VhdUri $osDiskUri2 -CreateOption fromImage -SourceImageUri $imageURI -Windows
New-AzureRmVM -ResourceGroupName $vmRG -Location $location -VM $vm2