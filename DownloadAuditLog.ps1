# 概要：
# 指定した期間のアクティビティログをダウンロードする。

####################################################################

# サブスクリプション名
$subscriptionName = "サブスクリプション名"

# ログ取得対象の開始日時
$startTime = "2016-09-01T00:00"
$endTime   = "2016-10-01T00:00"

####################################################################

Login-AzureRmAccount

Select-AzureRmSubscription -SubscriptionName $subscriptionName

Get-AzureRmLog -StartTime $startTime -EndTime $endTime
