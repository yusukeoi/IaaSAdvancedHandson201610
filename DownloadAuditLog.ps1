# 概要：
# 指定した期間のアクティビティログをダウンロードする。

####################################################################

# サブスクリプション名 (複数サブスクリプションがある場合は指定)
# $subscriptionName = "サブスクリプション名"

# ログ取得対象の開始日時 (yyyy-mm-ddTHH:MM 形式)
# 注意：指定できる期間は最大で15日
$startTime = "2016-09-20T00:00"
$endTime   = "2016-10-01T00:00"

# 書き出し先ファイルパス
$path = "C:\users\yooi\audit.csv"

####################################################################

Login-AzureRmAccount

# 複数サブスクリプションがある場合には実行
# Select-AzureRmSubscription -SubscriptionName $subscriptionName

Get-AzureRmLog -StartTime $startTime -EndTime $endTime | Out-File -FilePath $path
