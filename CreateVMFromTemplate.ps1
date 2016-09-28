# 概要：
# VMテンプレートから新規VMを作成する。

# 前提：
# 1. ストレージアカウントはすでに作成され、vhdsコンテナーにVMイメージがコピーされていること。(まだの場合はCreateStorageAccount.ps1を実行すること)
# 2. 仮想ネットワークはすでに作成されていること。またそのサブネットは1つだけであること。

####################################################################

# サブスクリプション名
$subscriptionName = "Hybrid ID"

# ストレージアカウント名(すでに作成済みという前提)
$storageAccountName = "yooiaad01d"
# ストレージアカウントおよびVMのリソースグループ名(すでに作成済みという前提)
$systemRG = "yooiaad01d"
# VMイメージ名(すでにストレージアカウントにコピー済みという前提)
$imageVHD = "template01201672915257.vhd"

# 仮想ネットワークのリソースグループ名(すでに作成済みという前提)
$vnetRG = "aad01-Migrated"
# 仮想ネットワーク名(すでに作成済みという前提)
$vnetName = "aad01"

# VMを作成する場所(ストレージアカウントや仮想ネットワークと同じ場所であること)
$location = "eastasia"

# Azure VM名
$vmName = "yooiaad01d"
# VMサイズ https://azure.microsoft.com/documentation/articles/virtual-machines-windows-sizes/
$vmSize = "Standard_D1_v2"
# (OS上の)コンピュータ名
$computerName = "yooiaad01d"
# VMの内部IP
$privateIP = "192.168.0.91"

# 課金IDタグ
$tags += @{Name="billingid";value="99999"}

####################################################################

Login-AzureRmAccount

Select-AzureRmSubscription -SubscriptionName $subscriptionName

# Windows OS上の管理者IDおよびパスワードの入力
$windowsAdmin = Get-Credential

$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $vnetRG -Name $vnetName  

# 外部IPの作成 (外部IPを付与しない場合は以下2行をコメントアウトすること)
$pipName = $vmName + "pip"
$pip = New-AzureRmPublicIpAddress -Name $pipName -ResourceGroupName $systemRG -Location $location -AllocationMethod Dynamic

# 仮想NICの作成および内部IPの指定
$nicName = $vmName + "nic"
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $systemRG -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -PrivateIpAddress $privateIP

$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $systemRG -Name $storageAccountName
$imageURI = $storageAccount.PrimaryEndpoints.Blob + "vhds/" + $imageVHD

# VMの作成
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize
$vm = Set-AzureRmVMOperatingSystem -VM $vmConfig -Windows -ComputerName $computerName -Credential $windowsAdmin -ProvisionVMAgent -EnableAutoUpdate
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id
$osDiskName = $vmName + "osdisk"
$osDiskUri = '{0}vhds/{1}-{2}.vhd' -f $storageAccount.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $osDiskName
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $osDiskUri -CreateOption fromImage -SourceImageUri $imageURI -Windows
New-AzureRmVM -ResourceGroupName $systemRG -Location $location -VM $vm -Tags $tags

