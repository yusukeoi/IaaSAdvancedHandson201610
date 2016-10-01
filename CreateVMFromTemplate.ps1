# 概要：
# VMテンプレートから新規VMを作成する。

# 前提：
# 1. ストレージアカウントはすでに作成され、vhdsコンテナーにVMイメージがコピーされていること。(まだの場合はCreateStorageAccount.ps1を実行すること)
# 2. 仮想ネットワークはすでに作成されていること。

####################################################################

# サブスクリプション名 (複数サブスクリプションがある場合は指定)
# $subscriptionName = "サブスクリプション名"

# ストレージアカウント名(すでに作成済みという前提)
$storageAccountName = "aztrNNst02"
# ストレージアカウントおよびVMのリソースグループ名(すでに作成済みという前提)
$systemRG = "aztrNNsys1-rg"
# VMイメージのURL(すでにストレージアカウントにコピー済みという前提)
$imageURI = "https://aztr99st02.blob.core.windows.net/vhds/vmtemplate-osDisk.758e818f-72f2-46b4-a447-fb612c924a16.vhd"

# 仮想ネットワークのリソースグループ名(すでに作成済みという前提)
$vnetRG = "aztrNNvnet-rg"
# 仮想ネットワーク名(すでに作成済みという前提)
$vnetName = "aztrNNvnet"

# VMを作成する場所(ストレージアカウントや仮想ネットワークと同じ場所であること)
$location = "japanwest"

# Azure VM名
$vmName = "aztrNNvm02"
# VMサイズ https://azure.microsoft.com/documentation/articles/virtual-machines-windows-sizes/
$vmSize = "Standard_D1_v2"
# (OS上の)コンピュータ名
$computerName = "aztrNNvm02"
# VMを配置するサブネット名
$subnetName = "DMZ"
# VMの内部IP
$privateIP = "10.0.0.10"

# 課金IDタグ
$tags += @{Name="billingid";value="99999"}

####################################################################

Login-AzureRmAccount

# 複数サブスクリプションがある場合には実行
# Select-AzureRmSubscription -SubscriptionName $subscriptionName

# Windows OS上の管理者IDおよびパスワードの入力
$windowsAdmin = Get-Credential

$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $vnetRG -Name $vnetName  

# 外部IPの作成 (外部IPを付与しない場合は以下2行をコメントアウトすること)
$pipName = $vmName + "pip"
$pip = New-AzureRmPublicIpAddress -Name $pipName -ResourceGroupName $systemRG -Location $location -AllocationMethod Dynamic

# 仮想NICの作成および内部IPの指定
$nicName = $vmName + "nic"
$subnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $systemRG -Location $location -SubnetId $subnet.Id -PublicIpAddressId $pip.Id -PrivateIpAddress $privateIP

$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $systemRG -Name $storageAccountName

# VMの作成
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize
$vm = Set-AzureRmVMOperatingSystem -VM $vmConfig -Windows -ComputerName $computerName -Credential $windowsAdmin -ProvisionVMAgent -EnableAutoUpdate
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id
$osDiskName = $vmName + "osdisk"
$osDiskUri = '{0}vhds/{1}-{2}.vhd' -f $storageAccount.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $osDiskName
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $osDiskUri -CreateOption fromImage -SourceImageUri $imageURI -Windows
New-AzureRmVM -ResourceGroupName $systemRG -Location $location -VM $vm -Tags $tags

