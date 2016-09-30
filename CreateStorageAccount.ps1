# 概要：
# VMを作成する前提となるストレージアカウントを作成し、既存の他ストレージアカウントから新たに作成したストレージアカウントにVMテンプレートをコピーする。

# 前提：
# 1. 既存の他ストレージアカウントのvhdsコンテナーにVMイメージが存在していること。

####################################################################

# サブスクリプション名
$subscriptionName = "サブスクリプション名"

# VMイメージが保管されているストレージアカウント名
$imageStorageAccoutName = "aztrNNst01"
# VMイメージが保管されているストレージアカウントのリソースグループ名
$imageStorageAccountRG = "aztrNNvm-rg"
# VMイメージが配置されているコンテナ (VMイメージのURLの最後の "/" の前まで)
$source = "https://aztr99st01.blob.core.windows.net/system/Microsoft.Compute/Images/vhds"
# VMイメージ名 (VMイメージのURLの最後の "/" の後ろ)
$imageVHD = "vmtemplate-osDisk.758e818f-72f2-46b4-a447-fb612c924a16.vhd"

# 新規作成するストレージアカウント名
$newStorageAccountName = "aztrNNst02"
# 新規作成するストレージアカウントのリソースグループ名
$newStorageAccountRG = "aztrNNsys1-rg"
# 新規作成するストレージアカウントの種類
$storageType = "Standard_LRS"
# 新規作成するストレージアカウントの場所
$location = "japanwest"

# 課金IDタグ
$tags += @{Name="billingid";value="99999"}

####################################################################

Login-AzureRmAccount

Select-AzureRmSubscription -SubscriptionName $subscriptionName

# VMイメージが保管されているストレージアカウントの取得
$imageStorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $imageStorageAccountRG -Name $imageStorageAccoutName

# 新規ストレージアカウントおよびリソースグループの作成
New-AzureRmResourceGroup -Name $newStorageAccountRG -Location $location
$newStorageAccount = New-AzureRmStorageAccount -ResourceGroupName $newStorageAccountRG -Name $newStorageAccountName -Location $location -SkuName $storageType -EnableEncryptionService Blob -Tag $tags

# 新ストレージアカウントのURL
$dest = $newStorageAccount.PrimaryEndpoints.Blob + "vhds"

# 新旧ストレージアカウントのアクセスキー取得
$sourceKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $imageStorageAccountRG -Name $imageStorageAccoutName)[0].Value
$destKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $newStorageAccountRG -Name $newStorageAccountName)[0].Value

# 新規ストレージアカウントのへのVMイメージのコピー
& 'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe' /Source:$source /Dest:$dest /SourceKey:$sourceKey /DestKey:$destKey /Pattern:$imageVHD
