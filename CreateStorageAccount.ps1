$subscriptionName = "Hybrid ID"

$imageStorageAccoutName = "test20160928"
$imageStorageAccountRG = "hoge"

$imageVHD = "template01201672915257.vhd"

$newStorageAccountName = "yooiaad01c"
$newStorageAccountRG = "hoge"

$storageType = "Standard_LRS"

$location = "eastasia"

Login-AzureRmAccount

Select-AzureRmSubscription -SubscriptionName $subscriptionName

$imageStorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $imageStorageAccountRG -Name $imageStorageAccoutName
$newStorageAccount = New-AzureRmStorageAccount -ResourceGroupName $newStorageAccountRG -Name $newStorageAccountName -Location $location -SkuName $storageType -EnableEncryptionService Blob

$source = $imageStorageAccount.PrimaryEndpoints.Blob + "vhds"
$dest = $newStorageAccount.PrimaryEndpoints.Blob + "vhds"

$sourceKey = (Get-AzureRmStorageAccountKey -ResourceGroupName imageStorageAccountRG -Name imageStorageAccountName)[0].Value
$destKey = (Get-AzureRmStorageAccountKey -ResourceGroupName newStorageAccountRG -Name newStorageAccountName)[0].Value

& 'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe' /Source:$source /Dest:$dest /SourceKey:$sourceKey /DestKey:$destKey /Pattern:$imageVHD
